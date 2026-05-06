module Help
  def print_usage
    usage_error_message = "Usage: stg <command> [options]

  Commands:\n"
    commands_docs = {
      init: 'Initialize the project',
      stage: 'add a file or directory to be tracked ',
      commit: 'Save the current tracked state ',
      diff: 'get the difference between working directory and the last commit ',
      log: 'print out commit history',
      reset: 'Revert to commit',
      checkout: 'check a commit or a branch without loss in data',
      branch: 'List all branches.',
      help: 'show this list'
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
end
