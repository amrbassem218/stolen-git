require 'optparse'
require_relative 'help'
require_relative 'actions'
require_relative 'stg/version'

module Stg
  class CLI
    extend Actions
    extend Help

    def self.start
      begin
        OptionParser.new do |opts|
          opts.banner = 'Usage: stg <command> [options]'

          opts.on('-v', '--version', 'Show version') do
            puts "stg version #{VERSION}"
            exit
          end

          opts.on('-h', '--help', 'Show this help') do
            puts print_usage
            exit
          end
        end.order!
      rescue OptionParser::ParseError
        # Ignore unknown options, let command handlers deal with them
      end

      command = ARGV.shift
      if !command || command.empty?
        puts print_usage
        return
      elsif command == 'init'
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

Stg::CLI.start if __FILE__ == $PROGRAM_NAME
