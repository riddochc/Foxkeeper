#!/usr/bin/env ruby

require 'fileutils'
include FileUtils::Verbose
require 'tempfile'
require 'rubygems'
require 'stringio'

def pipe_all(in_io, out_io)
  puts "Piping IO..."
  while data = in_io.read()
    begin
	puts "Read #{data.length} bytes"
      out_io.write(data)
      out_io.flush
    rescue Errno::EPIPE
    end
  end
end

def run_cmd_with_input(cmd, input_io)
  runcmd = cmd.join(' ')
  puts "Running: #{runcmd}"
  io = IO.popen(runcmd, "w+")
  io.print(input_io.read())
  io.close_write
  if block_given?
    retval = yield(io)
  else
    retval = ""
    while data = io.read(2 ** 14)
      retval << data
    end
  end
  io.close_read
  retval
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
  `dump.sh #{in_filename} #{out_filename}`  
  table_text = run_cmd_with_input(["/usr/bin/sqlite3", in_filename], ".tables\n")
  table_text.lines.map {|line| line.split(/\s+/)}.flatten.each do |table|
    run_cmd_with_input(["/usr/bin/sqlite3", in_filename], ".dump #{table}") do |in_io|
      pipe_all(in_io, out_io)
    end
  end
  nil
end

case ARGV[0]
when "clean"  # stdin = db, stdout = sql
  if ARGV[1].nil?
    tf = Tempfile.new('ff')
    pipe_all(STDIN, tf)
    tf.close
    path = tf.path
  else
    path = ARGV[1]
  end
  dump_sqlite(STDOUT, path)
when "smudge" # stdin = sql, stdout = db
  if ARGV[1].nil?
    tf = Tempfile.new('ff')
    run_cmd_with_input(["sqlite3", tf.path], STDIN)
    tf.rewind
    pipe_all(tf, STDOUT)
    tf.close
  else
    run_cmd_with_input(["sqlite3", ARGV[1]], STDIN)
  end
when "install"
  if File.exists?(".git")
    File.open(".gitattributes", 'a+') {|f|
      f.puts
      f.puts("*.sqlite    filter=sqlite")
    }
    `git config filter.sqlite.clean \"#{$0} clean %f\"`
    `git config filter.sqlite.smudge \"#{$0} smudge %f\"`
  else
    puts "Not a git repository?"
  end
else
  puts "Please specify clean, smudge, or install operation."
end


