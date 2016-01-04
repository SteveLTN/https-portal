#!/usr/bin/env ruby

def prompt(*args)
    print(*args)
    gets
end

input = prompt "Warning: The tests will delete all your containers and volumes on the host. Continue? (y/N)"

if input.strip == 'y'
  $:<<'suites'  # add to load path
  files = Dir.glob('suites/**/*.rb')
  files.each{|file| require file.gsub(/^suites\/|.rb$/,'')}
end
