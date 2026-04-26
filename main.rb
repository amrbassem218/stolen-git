require 'optparse'
require 'digest'
require_relative 'differencing'
require_relative 'help'
require_relative 'utils'
require_relative 'actions'

command = ARGV.shift
NAME = 'stolen-git'
actions = Actions.new
case command
when 'init'
  actions.p_initialize

when 'commit'
  actions.commit

when 'diff'
  actions.diff
when 'test'
  actions.test

when 'stage'
  actions.stage

when 'check_router'
  actions.check_router
when 'reset'
  puts 'Reverting to latest changes...'

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
