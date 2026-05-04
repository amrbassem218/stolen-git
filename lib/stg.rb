require_relative 'help'
require_relative 'actions'

module Stg
  class CLI
    extend Actions
    extend Help

    def self.start
      command = ARGV.shift
      if command == 'init'
        p_initialize
        return
      else
        return unless check_program_exists
      end

      case command
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
      when 'checkout'
        checkout
      when 'branch'
        branch
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
    end
  end
end

Stg::CLI.start
