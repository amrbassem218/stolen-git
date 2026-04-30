module Help
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
end
