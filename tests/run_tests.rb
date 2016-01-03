#!/usr/bin/env ruby

$:<<'suites'  # add to load path
files = Dir.glob('suites/**/*.rb')
files.each{|file| require file.gsub(/^suites\/|.rb$/,'')}
