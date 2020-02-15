#!/usr/bin/env ruby

require 'net/ssh'
RSYNC=%x[ which rsync 2>/dev/null ].chomp
raise "rsync: command not found" unless $?.exitstatus == 0

mode    = :development
dry_run = false
CWD     = Dir.pwd  # Set Current Working Directory

while !ARGV.empty? do
  arg = ARGV.shift
  case arg
    when "-d","--dry-run" then dry_run = true
    else mode = arg.to_sym
  end
end

config = {
  development: {
    server: "dev.server.tld",
    location: "/some/path/",
    user: "root"
  },
  testing: {
    server: "localhost",
    location: "/tmp/publish test",
    user: "#{ ENV['USER'] }"
  },
  production: {
    server: "live.server.tld",
    location: "/some/path/",
    user: "root"
  }
}

exclude = [
  ".git/",
  ".gitignore",
  "bin/",
]

include = []

if config[mode].nil?
  puts "Mode not found"
  exit 1
end

puts "DRY RUN" if dry_run
puts "You're about to sync your current branch (#{ CWD }/) with '#{ config[mode][:user] }@#{ config[mode][:server] }':'#{ config[mode][:location] }', this will remove all local changes."
print "Are you sure you want to continue? [no] "
exit unless $stdin.gets.chomp == "yes"

command = "#{ RSYNC } -Rcvrh --progress --delete --force"
command += exclude.map{|s| " --exclude='#{ s }'"}.join unless exclude.empty?
command += " '#{ CWD }/./'"
command += include.map{|s| " '#{ CWD }/./#{ s }'" }.join unless include.empty?
command += " '#{ config[mode][:user] }@#{ config[mode][:server] }':\"'#{ config[mode][:location] }'\""

if dry_run
  command += " --dry-run"
  puts
  puts command
  puts
  system(command)
  exit
end

Net::SSH.start(config[mode][:server], config[mode][:user]) do |ssh|
  ssh.exec!("mkdir -p '#{ config[mode][:location] }'")
end

system(command)

exit
