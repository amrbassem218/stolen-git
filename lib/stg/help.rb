module Help
  def print_usage
    usage_error_message = "Usage: stg <command> [options]

  Commands:\n"
    commands_docs = {
      init: 'Initialize the project',
      stage: 'Add files or directories to the index',
      commit: 'Save the current indexed state',
      diff: 'Show differences between the working directory and the last commit',
      log: 'Print commit history',
      reset: 'Restore from the index, or restore a commit when an id is provided',
      checkout: 'Check out a branch, or a commit with -c',
      branch: 'List branches, or create a branch when a name is provided',
      help: 'Show this list'
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
