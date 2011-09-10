#!/usr/bin/env ruby

require 'rubygems'
require 'parseconfig'
require 'yaml'
require 'fileutils'
include FileUtils::Verbose

profiledir = ENV['HOME'] + "/.mozilla/firefox/"
profile = ParseConfig.new(profiledir + "profiles.ini")

profile_name = ARGV[0] || "default"
relative_dir = (profile.params.find {|k, v| v["Name"] == profile_name }[1]["IsRelative"] == "1")
profile_path = profile.params.find {|k, v| v["Name"] == profile_name }[1]["Path"]

if relative_dir == true
  fullprofiledir = File.expand_path(profile_path, profiledir)
else
  fullprofiledir = profile_path
end

cd fullprofiledir do
  system('gitk')
  system('firefox', '-P', 'profile')
  system('git', 'add', '.')
  system('git', 'gui')
end

