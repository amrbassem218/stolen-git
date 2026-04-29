require_relative 'help'
require_relative 'actions'

command = ARGV.shift
NAME = 'stolen-git'
include Actions
case command
when 'init'
  p_initialize

when 'commit'
  commit

when 'diff'
  diff
when 'test'
  test

when 'stage'
  stage

when 'check_router'
  check_router
when 'reset'
  reset
when 'log'
  log
when 'help'
  puts print_usage
  exit 1

when nil
  puts print_usage
  exit 1

else
  puts "Unknown command: #{command}"
  exit 1
end
