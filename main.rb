require 'optparse'

command = ARGV.shift
def print_usage
  usage_error_message = "Usage: mygit <command> [options]

  Commands:\n"
  commands_docs = {
    commit: 'Save changes',
    reset: 'Revert to commit'
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

case command
when 'push'
  puts 'Pushing code...'

when 'commit'
  puts 'Committing changes...'

when 'pull'
  puts 'Pulling latest changes...'

when nil
  puts print_usage
  exit 1

else
  puts "Unknown command: #{command}"
  exit 1
end
