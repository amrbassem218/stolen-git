require 'optparse'
require 'colorize'
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

class DiffCalc
  attr_reader :mem, :cnt

  def initialize
    @mem = {}
    @cnt = 1
  end

  def differencing(old_s, new_s, i1 = 0, i2 = 0)
    return @mem[[i1, i2]] unless @mem[[i1, i2]].nil?
    if i1 >= old_s.length && i2 >= new_s.length
      return { insertion_seq: {}, deletion_seq: [], insertions: 0,
               deletions: 0, diff_cnt: 0 }
    end

    if i1 >= old_s.length
      trailing_ins = new_s.length - i2
      insertion_seq = {}
      (i2...new_s.length).each do |i|
        insertion_seq[i] = new_s[i]
      end
      return { insertions: trailing_ins, deletions: 0, insertion_seq: insertion_seq,
               deletion_seq: [], diff_cnt: trailing_ins }

    elsif i2 >= new_s.length
      trailing_del = old_s.length - i1
      deletion_seq = (i1...old_s.length).to_a

      return { insertions: 0, deletions: trailing_del, insertion_seq: {},
               deletion_seq: deletion_seq, diff_cnt: trailing_del }
    end

    default_path = { diff_cnt: 2**63 - 1, insertion_seq: {}, deletion_seq: [], insertions: 0, deletions: 0 }
    min_path = default_path

    if old_s[i1] == new_s[i2]
      keep = differencing(old_s, new_s, i1 + 1, i2 + 1)
      min_path = keep if keep && (keep[:insertions] + keep[:deletions] < min_path[:diff_cnt])
    else
      del = differencing(old_s, new_s, i1 + 1, i2)
      add = differencing(old_s, new_s, i1, i2 + 1)

      [del, add].each do |path|
        next unless path

        next unless path[:insertions] + path[:deletions] < min_path[:diff_cnt]

        is_add = path == add
        insertions = is_add ? path[:insertions] + 1 : path[:insertions]
        deletions = is_add ? path[:deletions] : path[:deletions] + 1

        insertion_seq = path[:insertion_seq].dup
        deletion_seq = path[:deletion_seq].dup
        if is_add
          insertion_seq[i2] = new_s[i2]
        else
          deletion_seq = [i1] + deletion_seq
        end
        min_path = {
          diff_cnt: insertions + deletions,
          insertions: insertions,
          deletions: deletions,
          insertion_seq: insertion_seq,
          deletion_seq: deletion_seq
        }
      end

    end
    @mem[[i1, i2]] = min_path unless min_path == default_path
    @cnt += 1
    min_path
  end
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
    # diff = differencing(old_content, new_content, 0, 0, '', 0, 0, {})
    # puts "Diff: #{diff}"
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
    file_b = File.read(files[1]).split("\n")
    diff_calc = DiffCalc.new
    diff = diff_calc.differencing(file_a, file_b)
    insertions, deletions, insertion_seq, deletion_seq = diff.values_at(:insertions, :deletions, :insertion_seq,
                                                                        :deletion_seq)

    # debug
    # puts '**FILE A ***'
    # print file_a
    # puts
    #
    # puts '**FILE B ***'
    # print file_b
    # puts
    #
    # puts '** Diff***'
    # puts diff
    # puts

    # sorting insertion_seq by keys
    insertion_seq = insertion_seq.sort.to_h
    insertion_seq_keys = insertion_seq.keys
    puts "Diff: (+): #{insertions}    (-): #{deletions}"

    # printing diff
    insertion_poniter = 0
    deletion_pointer = 0

    # index (old or new)
    # value (styled text to be printed)
    # type (1 => insertion, 0 => deletion)
    edit_list = []
    while insertion_poniter < insertions && deletion_pointer < deletions
      is_insertion = true
      is_insertion = if insertion_poniter >= insertions
                       false
                     else
                       insertion_seq_keys[insertion_poniter] < deletion_seq[deletion_pointer]
                     end
      index = is_insertion ? insertion_seq_keys[insertion_poniter] : deletion_seq[deletion_pointer]

      if is_insertion
        edit_list.push({ index: index, value: "+#{insertion_seq[index]}".green, type: 1 })
        insertion_poniter += 1
      else
        edit_list.push({ index: index, value: "-#{file_b[index]}".red, type: 0 })
        deletion_pointer += 1
      end

    end

    MAX_SPACE_DIFF = 3
    is_new_block = true
    print_queue = []
    block_queu = []
    block_inserts = 0
    block_deletions = 0
    edit_list.each_with_index do |order, i|
      is_new_block = false
      # Printing Context Before
      if i == 0
        (order[:index] - MAX_SPACE_DIFF..order[:index] - 1).each do |j|
          block_queu.push({ index: j, value: file_a[j] }) if j >= 0
        end
      elsif order[:index] - edit_list[i - 1][:index] + 1 <= MAX_SPACE_DIFF
        (edit_list[i - 1][:index] + 1..order[:index] - 1).each do |j|
          block_queu.push({ index: j, value: file_a[j] }) if j >= 0
        end
      # elsif editlist[i-1][:index] + MAX_SPACE_DIFF >= order[:index] - MAX_SPACE_DIFF

      else
        (order[:index] - MAX_SPACE_DIFF..order[:index] - 1).each do |j|
          block_queu.push({ index: j, value: file_a[j] }) if j >= 0
        end

      end

      # Printing actual line
      block_queu.push({ index: j, value: order[:value] })

      if order[:type] == 1
        block_inserts += 1
      else
        block_deletions += 1
      end

      # Printing Context After in Case Block is done
      next unless i + 1 < order.length && edit_list[i + 1][:index] - edit_list[i][:index] > MAX_SPACE_DIFF

      (order[:index] + 1..order[:index] + MAX_SPACE_DIFF).each do |j|
        block_queu.push({ index: j, value: file_a[j] }) if j >= 0
      end

      if block_queu.length.positive?
        print_queue.push({ block: block_queu, start_index: block_queu.first[:index], insertions: block_inserts,
                           deletions: block_deletions })
      end
      block_queu = []
      block_inserts = 0
      block_deletions = 0
      is_new_block = true
    end
    if block_queu.length.positive?
      print_queue.push({ block: block_queu, start_index: block_queu.first[:index], insertions: block_inserts,
                         deletions: block_deletions })
    end

    print_queue.each do |block|
      # puts "block:#{block}"
      print "@@ #{block[:start_index]}, +#{block[:insertions]} -#{block_deletions} @@ ".light_blue
      block[:block].each { |line| puts line[:value] }
      puts
    end
  end
when 'test'
  s1 = "a
    b
    c
    d"

  s2 = "a
    bcd"
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
  diff = calc.differencing(s1, s2)

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
