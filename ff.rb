#!/usr/bin/env ruby

require 'rubygems'
require 'dialog-fu'
require 'facets'
require 'yaml'
require 'fileutils'
include FileUtils::Verbose

profiledir = ENV['HOME'] + "/.mozilla/firefox/"

class Array
  def rest
    self[1,self.length-1]
  end
end

def readini(f)
  ini = {}
  f.readlines.divide(/^\[.*\]\s*$/).each { |section|
    if section[0] =~ /^\[(.*)\]\s*$/
      title = $1
    else
      title = "Untitled"
    end
    pairs = section.rest.collect { |keyval|
      keyval.chomp.split(/=/)
    }.to_h
    ini[title] = pairs
  }
  ini
end

File.open(profiledir + "profiles.ini", 'r') do |f|
  ini = readini(f)
  profile_to_dir = {}
  ini.each_value {|h|
    unless h['Name'].nil?
      profile_to_dir[h['Name']] = h['Path']
    end
  }
  profile_to_dir.to_yaml
  profile = selection_list(profile_to_dir.keys, :text => "Profile")
  
  fullprofiledir = profiledir + profile_to_dir[profile]
  puts fullprofiledir

  cd fullprofiledir do
    `/home/riddochc/ff-git/reload-sqlite.rb`
    `firefox -P "#{profile}"`
    `/home/riddochc/ff-git/dump-sqlite.rb`
    `git add .`
    `git gui`
  end
end

