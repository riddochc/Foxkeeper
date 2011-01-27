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

Dir.glob("**/*.dump").each do |f|
  base = File.basename(f, ".dump")
  run_cmd_with_input(["sqlite3", "#{base}.sqlite"], File.open(f, 'r').read)
  # rm(f)
end


