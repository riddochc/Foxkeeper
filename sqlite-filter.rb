#!/usr/local/bin/ruby

require 'fileutils'
include FileUtils::Verbose
require 'tempfile'
require 'stringio'


def dump_sql(in_filename, out_io)
  tables_output = IO.popen(["/usr/bin/sqlite3", in_filename], "w+") do |pipe|
    pipe.puts ".tables"
    pipe.close_write
    pipe.read
  end

  tables_output.lines.map {|line| line.split(/\s+/)}.flatten.each do |table|
    table_dump = IO.popen(["/usr/bin/sqlite3", in_filename], "w+") {|pipe|
      pipe.puts ".dump #{table}"
      pipe.close_write
      pipe.read
    }
    IO.copy_stream(StringIO.new(table_dump), out_io)
  end
  nil
end

def dump_db(input, output)
  db_tempfile = Tempfile.new('ff.db')

  IO.popen(["sqlite3", db_tempfile.path], "w+") do |pipe|
    IO.copy_stream(input, pipe)
    pipe.close_write
    pipe.close_read
  end

  IO.copy_stream(db_tempfile.path, output)
  nil
end

case $0
when /sqlite-clean/  # stdin = db, stdout = sql
  if ARGV[1].nil?
    tf = Tempfile.new('ff.db')
    IO.copy_stream(STDIN, tf)
    tf.close
    path = tf.path
  else
    path = ARGV[1]
  end
  dump_sql(path, STDOUT)
when /sqlite-smudge/ # stdin = sql, stdout = db
  if ARGV[1].nil?
    input_stream = STDIN
  else
    input_stream = ARGV[1]
  end

  dump_db(input_stream, STDOUT)
when /sqlite-filter-install/
  if File.exists?(".git")
    File.open(".gitattributes", 'a+') {|f|
      f.puts
      f.puts("*.sqlite    filter=sqlite")
    }
    system("git", "config", "filter.sqlite.clean", File.expand_path("sqlite-clean.rb", File.dirname(__FILE__)))
    system("git", "config", "filter.sqlite.smudge", File.expand_path("sqlite-smudge.rb", File.dirname(__FILE__)))
  else
    puts "Not a git repository?"
  end
else
  puts "Please specify clean, smudge, or install operation."
end


