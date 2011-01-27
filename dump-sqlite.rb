#!/usr/bin/env ruby

require 'fileutils'
include FileUtils::Verbose

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

def dump_sqlite(in_file)
  table_text = run_cmd_with_input(["/usr/bin/sqlite3", in_file], ".tables\n")
  tables = table_text.lines.map {|line| line.split(/\s+/)}.flatten
  File.open(basename(in_file) + '.dump', 'w+') do |out_file|
    tables.each {|t| out_file.write(sqlite_table_sql(in_file, t)) }
  end
  nil
end

Dir.glob("**/*.sqlite").each do |f|
	puts "Sqlite file: #{f}"
  dump_sqlite(f)
end

# puts sqlite_table_sql('places.sqlite', 'moz_favicons')

