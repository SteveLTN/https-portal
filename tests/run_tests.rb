#!/usr/bin/env ruby

def prompt(*args)
    print(*args)
    gets
end

input = prompt "Warning: The tests will delete all your containers and volumes on the host. Continue? (y/N)"

if input.strip == 'y'
  # Clean up docker machine
  `docker rm -f -v $(docker ps -qa)`
  $:<<'suites'  # add to load path
  files = Dir.glob('suites/**/*.rb')
  files.each{|file| require file.gsub(/^suites\/|.rb$/,'')}
end
