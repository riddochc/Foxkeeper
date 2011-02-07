#!/usr/bin/env ruby

require 'fileutils'
include FileUtils::Verbose
require 'tempfile'
require 'rubygems'

def run_cmd_with_input(cmd, input)
  if cmd.kind_of? String
    cmd = [cmd]
  end
  io = IO.popen(cmd, "w+")
  io.print(input)
  io.close_write
  out = io.read()
  io.close_read
  out
end

def sqlite_table_sql(file, table)
  run_cmd_with_input(["/usr/bin/sqlite3", file], ".dump #{table}")
end


def basename(*args)
  if args.length > 1
    File.basename(*args)
  else
    begin
      /(.+)\.[^.]+$/.match(args[0])[1]
    rescue NoMethodError
      nil
    end
  end
end

def dump_sqlite(out_io, in_filename)
  table_text = run_cmd_with_input(["/usr/bin/sqlite3", in_filename], ".tables\n")
  table_text.lines.map {|line| line.split(/\s+/)}.flatten.each { |t|
    out_io.write(sqlite_table_sql(in_filename, t))
  }
  nil
end

case ARGV[0]
when "clean"  # stdin = db, stdout = sql
  if ARGV[1].nil?
    tf = Tempfile.new('ff')
    tf.write(STDIN.read(nil))
    tf.close
    path = tf.path
  else
    path = ARGV[1]
  end
  dump_sqlite(STDOUT, path)
when "smudge" # stdin = sql, stdout = db
  if ARGV[1].nil?
    tf = Tempfile.new('ff')
    run_cmd_with_input(["sqlite3", tf.path], STDIN.read(nil))
    tf.rewind
    print(tf.read(nil))
    tf.close
  else
    run_cmd_with_input(["sqlite3", ARGV[1]], STDIN.read(nil))
  end
when "install"
  if File.exists?(".git")
    File.open(".gitattributes", 'a+') {|f|
      f.write("\n*.sqlite    filter=sqlite   diff=sqlite\n")
    }
    `git config filter.sqlite.clean \"#{$0} clean %f\"`
    `git config filter.sqlite.smudge \"#{$0} smudge %f\"`
    `git config diff.sqlite.textconv \"#{$0} clean %f\"`
  else
    puts "Not a git repository?"
  end
else
  puts "Please specify clean, smudge, or install operation."
end


