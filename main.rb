require 'optparse'
require 'colorize'
require 'fileutils'
require 'digest'
require 'json'
require_relative 'differencing'

command = ARGV.shift
NAME = 'stolen-git'
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

def confirm?(prompt)
  loop do
    print "#{prompt} (y/n): "
    input = gets.chomp.downcase
    case input
    when 'y'
      return true
    when 'n'
      return false
    else
      puts 'wrong input only enter y/n'
    end
  end
end

def p_initialize
  # Check if already initialized
  if File.exist?('.stolen-git')
    if confirm?('An instance of stolen-git is already up here do you want to replace it')
      if confirm?('THIS WILL DELETE ALL COMMITS AND INSTANCES OF stolen-git. ARE YOU SURE')
        FileUtils.rm_rf('.stolen-git')

        if File.exist?('.stolen-git')
          puts 'An error occured during the deletion process of the old directory of stolen-git'
        else
          p_initialize
        end
      else
        puts 'ok'
      end
    else
      puts 'ok'
    end

  else
    FileUtils.mkdir_p('.stolen-git')
    FileUtils.mkdir_p('.stolen-git/commits')

    FileUtils.mkdir_p('.stolen-git/last')
    FileUtils.write('.stolen-git/last/router.json', {})

    File.write('.stolen-git/project_info.json', {})
    File.write('.stolen-git/commits.json', [])
    File.write('.stolen-git/staged.json', [])
    puts "#{NAME.capitalize} initialized Sucessfully :D"
  end
end

def get_file_hash(path)
  Digest::SHA256.file(path).hexdigest
end

def stage(_files)
  File.read('.stolen-git/staged.json')
  files.each do |file|
    file_hash = get_file_hash(file)
    router = JSON.parse(File.read('./stolen-git/last/router.json'))
    next unless router.key?(file_hash)

    old_file = File.read(router[:file_hash])
    File.read(old_file)
    File.read(old_file)
  end
end

case command
when 'init'
  p_initialize

when 'commit'
  commit

when 'diff'
  files = ARGV
  if files.length < 2
    puts 'Usage: stolen-git diff <first_file> <second_file>'
  else
    file_a = File.read(files[0]).split("\n")
    file_b =  File.read(files[1]).split("\n")
    diff_calc = DiffCalc.new
    diff_calc.print_diff(file_a, file_b)
  end

when 'test'
  s1 = "a
    b
    c
    d"

  s2 = "a
    k
    k
  k
  c
  d"
  calc = DiffCalc.new
  # s1 = 'abcd'
  # s2 = 'aabcd'

  tests = ARGV
  puts "tests: #{tests}"
  if tests && tests.length >= 2
    s1 = tests[0]
    s2 = tests[1]
  end
  s1 = s1.split("\n")
  s2 = s2.split("\n")
  calc.compute_diff(s1, s2)
  diff = calc.build_sequences

  puts ''

  print s1
  puts

  puts '***b***'
  print s2
  puts

  puts "diff_cnt: #{diff[:diff_cnt]}"
  puts "insertion_seq: #{diff[:insertion_seq]}"
  puts "deletion_seq: #{diff[:deletion_seq]}"
  puts "diff_insertions: #{diff[:insertions]}"
  puts "diff_deletions: #{diff[:deletions]}"
  puts "cnt: #{calc.cnt}"
  # puts 'mem:'
  # calc.mem.each do |key, val|
  #   puts "#{key}: #{val}"
  # end
  # test_sub = { bro: 'hi' }.merge(key => 'hey')
  # ; print "test_seq: #{test_sub}"

when 'stage'
  files = ARG[1..]
  if files.empty?
    puts 'Usage: stolen-git stage <files..>'
  else
    stage(files)
  end
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
