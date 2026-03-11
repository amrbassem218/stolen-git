require 'optparse'
require 'fileutils'
command = ARGV.shift
def print_usage
  usage_error_message = "Usage: stolen-git <command> [options]

  Commands:\n"
  commands_docs = {
    commit: 'Save changes',
    reset: 'Revert to commit',
    init: 'Initialize stolen-git to start tracking'
  }
  max_len = 0
  commands_docs.each_key do |command|
    max_len = max_len > command.length ? max_len : command.length
  end
  commands_docs.each do |key, value|
    command = key.to_s
    usage_error_message << '    ' << command << ' ' * (max_len - command.length) << '   ' << value << "\n"
  end
  puts usage_error_message
end

def initialize
  if File.exist?('.stolen-git')
    loop do
      print 'An instance of stolen-git is already up here do you want to replace it (y/n): '
      replace_user_input = gets.chomp.downcase
      case replace_user_input
      when 'y'
        loop do
          print 'THIS WILL DELETE ALL COMMITS AND INSTANCES OF STOLEN-GIT. ARE YOU SURE (y/n): '
          confirmation_user_input = gets.chomp.downcase
          case confirmation_user_input
          when 'y'
            FileUtils.rm_rf('.stolen-git')
            if File.exist?('.stolen-git')
              puts 'An error occured during the deletion process of the old directory of stolen-git'
            else
              initialize
            end
            break
          when 'n'
            puts 'ok'
            break
          else
            puts 'wrong input only enter y/n'
          end
        end
        break
      when 'n'
        puts 'ok'
        break
      else
        puts 'wrong input only enter y/n'
      end
    end
  else
    Dir.mkdir('.stolen-git')

  end
end

case command
when 'init'
  initialize
  puts 'Stolen-git initzlized Sucessfully :D'

when 'commit'
  puts 'Committing changes...'

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
