require 'optparse'
require 'fileutils'
require 'digest'
require 'json'

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

def differencing(old_s, new_s, i1, i2, curr, diff_cnt, diff_seq)
  # puts "i1: #{i1}   i2: #{i2}  curr: #{curr}   diff_cnt: #{diff_cnt}"
  # print "diff_seq: #{diff_seq}\n"
  if i1 >= old_s.length
    trailing_add = (new_s.length - curr.length)
    diff_cnt += trailing_add
    for i in (1..trailing_add)
      recorded_index = i + new_s.length - 1
      diff_seq = diff_seq.merge(recorded_index => new_s[i2 + i - 1])
    end

    return { diff_cnt: diff_cnt, diff_seq: diff_seq }
  end

  return { diff_cnt: diff_cnt, diff_seq: diff_seq } if i2 >= new_s.length

  min_diff = 2**63 - 1
  min_seq = {}
  if old_s[i1] == new_s[i2]
    keep = differencing(old_s, new_s, i1 + 1, i2 + 1, curr + old_s[i1], diff_cnt, diff_seq)
    if keep[:diff_cnt] < min_diff
      min_diff = keep[:diff_cnt]
      min_seq =  keep[:diff_seq]
    end
  else
    del = differencing(old_s, new_s, i1 + 1, i2, curr, diff_cnt + 1, diff_seq.merge(i1 => ''))
    replace = differencing(old_s, new_s, i1 + 1, i2 + 1, curr + new_s[i2], diff_cnt + 1,
                           diff_seq.merge(i1 => new_s[i2]))
    # puts "dle_diff_cnt: #{del[:diff_cnt]}    replace_diff_cnt: #{replace[:diff_cnt]}"
    if [del[:diff_cnt], replace[:diff_cnt]].min < min_diff
      if del[:diff_cnt] < replace[:diff_cnt]
        min_diff = del[:diff_cnt]
        min_seq = del[:diff_seq]
      else
        min_diff = replace[:diff_cnt]
        min_seq = replace[:diff_seq]
      end
    end
  end
  { diff_cnt: min_diff, diff_seq: min_seq }
end

def stage(_files)
  File.read('.stolen-git/staged.json')
  files.each do |file|
    file_hash = get_file_hash(file)
    router = JSON.parse(File.read('./stolen-git/last/router.json'))
    next unless router.key?(file_hash)

    old_file = File.read(router[:file_hash])
    old_content = File.read(old_file)
    new_content = File.read(old_file)
    diff = differencing(old_content, new_content, 0, 0, '', 0, {})
    puts "Diff: #{diff}"
  end
end

case command
when 'init'
  p_initialize

when 'commit'
  commit

when 'test'
  s1 = 'abcd'
  s2 = 'bcde'
  diff = differencing(s1, s2, 0, 0, '', 0, {})
  puts "diff_cnt: #{diff[:diff_cnt]}"
  puts "diff_seq: #{diff[:diff_seq]}"
  # test_sub = { bro: 'hi' }.merge(key => 'hey')
  # print "test_seq: #{test_sub}"

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
