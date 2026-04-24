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
  attr_reader :mem, :cnt, :old_s, :new_s

  def initialize
    @mem = {}
    @cnt = 0
  end

  def compute_diff(old_arr, new_arr)
    @old_s = old_arr
    @new_s = new_arr
    differencing(0, 0)
  end

  def differencing(i1 = 0, i2 = 0)
    cached = @mem[[i1, i2]]
    return cached if cached

    if i1 >= @old_s.length && i2 >= @new_s.length
      result = { diff_cnt: 0, insertions: 0, deletions: 0, action: :done }
      @mem[[i1, i2]] = result
      return result
    end

    if i1 >= @old_s.length
      result = { diff_cnt: @new_s.length - i2, insertions: @new_s.length - i2, deletions: 0, action: :insert }
      @mem[[i1, i2]] = result
      return result
    end

    if i2 >= @new_s.length
      result = { diff_cnt: @old_s.length - i1, insertions: 0, deletions: @old_s.length - i1, action: :delete }
      @mem[[i1, i2]] = result
      return result
    end

    if @old_s[i1] == @new_s[i2]
      result = differencing(i1 + 1, i2 + 1)
      result = { diff_cnt: result[:diff_cnt], insertions: result[:insertions], deletions: result[:deletions],
                 action: :keep }
      @mem[[i1, i2]] = result
      return result
    end

    del = differencing(i1 + 1, i2)
    add = differencing(i1, i2 + 1)

    del_cost = del[:diff_cnt] + 1
    add_cost = add[:diff_cnt] + 1

    result = if del_cost <= add_cost
               { diff_cnt: del_cost, insertions: del[:insertions], deletions: del[:deletions] + 1, action: :delete }
             else
               { diff_cnt: add_cost, insertions: add[:insertions] + 1, deletions: add[:deletions], action: :insert }
             end

    @mem[[i1, i2]] = result
    result
  end

  def build_sequences
    i1 = 0
    i2 = 0
    insertion_seq = {}
    deletion_seq = {}

    while i1 < @old_s.length || i2 < @new_s.length
      action = @mem[[i1, i2]][:action]

      case action
      when :done
        break
      when :keep
        i1 += 1
        i2 += 1
      when :delete
        deletion_seq[i2] ||= []
        deletion_seq[i2].push({ old_index: i1, ma_type: 'bs' })
        i1 += 1
      when :insert
        insertion_seq[i2] = { value: @new_s[i2], old_index: i1 }
        i2 += 1
      end
    end

    result = @mem[[0, 0]]
    {
      insertion_seq: insertion_seq,
      deletion_seq: deletion_seq,
      insertions: result[:insertions],
      deletions: result[:deletions],
      diff_cnt: result[:diff_cnt]
    }
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
    diff_calc.compute_diff(file_a, file_b)
    diff = diff_calc.build_sequences
    insertions, deletions, insertion_seq, deletion_seq = diff.values_at(:insertions, :deletions, :insertion_seq,
                                                                        :deletion_seq)
    # sorting insertion_seq by keys
    insertion_seq = insertion_seq.sort.to_h
    insertion_seq_keys = insertion_seq.keys

    deletion_seq = deletion_seq.sort.to_h
    deletion_seq_keys = deletion_seq.keys

    puts "Diff: (+): #{insertions}    (-): #{deletions}"

    # printing diff
    insertion_poniter = 0
    deletion_pointer = 0

    # index (old or new)
    # value (styled text to be printed)
    # type (-1 => deletion, 0 => insertion, 1 => not changed)
    edit_list = []
    while insertion_poniter < insertions || deletion_pointer < deletion_seq_keys.length
      is_insertion = true
      is_insertion = if insertion_poniter >= insertions
                       false
                     elsif deletion_pointer >= deletion_seq_keys.length
                       true
                     else
                       insertion_seq_keys[insertion_poniter] < deletion_seq_keys[deletion_pointer]
                     end
      index = is_insertion ? insertion_seq_keys[insertion_poniter] : deletion_seq_keys[deletion_pointer]
      if is_insertion
        edit_list.push({ index: index, value: "#{insertion_seq[index][:value]}", type: 0,
                         old_index: insertion_seq[index][:old_index] })
        insertion_poniter += 1
      else
        deletion_seq[index] = deletion_seq[index].sort_by { |del| del[:old_index] }
        deletion_seq[index].each do |del|
          old_index = del[:old_index]
          edit_list.push({ index: index, value: "#{file_a[old_index]}", type: -1,
                           old_index: old_index })
        end
        deletion_pointer += 1
      end

    end

    MAX_SPACE_DIFF = 3
    print_queue = {}
    edit_list.each_with_index do |order, _i|
      (order[:index] - MAX_SPACE_DIFF..order[:index] + MAX_SPACE_DIFF).each do |j|
        next unless j >= 0 && j < file_b.length

        line = order[:index] == j ? order : { index: j, value: file_b[j], type: 1, old_index: j }
        print_queue[j] ||= []
        print_queue[j].push(line) unless line[:type] == 1 && print_queue[j].length.positive?
      end
    end

    print_queue = print_queue.sort.to_h
    print_queue_keys = print_queue.keys
    printed = {}

    def print_line(line)
      sign = if line[:type] == -1
               '-'
             else
               line[:type] == 0 ? '+' : ''
             end

      index = if line[:type] == -1
                line[:old_index]
              else
                line[:index]
              end
      print_text = "#{index} #{sign}#{line[:value]}"
      if line[:type] == -1
        print_text = print_text.red
      elsif line[:type] == 0
        print_text = print_text.green
      end
      puts print_text
    end

    print_queue.each_with_index do |(index, lines), queue_i|
      lines = lines.sort_by { |line| line[:type] }
      is_changed = false
      lines.each do |line, _i|
        next if printed[[index, line[:type]]] == 1

        # puts "index: #{index}  type:#{line[:type]}  "

        print_line(line) unless is_changed == true && line[:type] == 1
        is_changed = true

        next unless line[:type] == -1

        j = queue_i + 1

        define_method :is_deletion? do
          return false if j >= print_queue_keys.length

          print_queue[print_queue_keys[j]]&.any? { |x| x[:type] == -1 }
        end

        while is_deletion?
          q_i = print_queue_keys[j]
          cur_line = print_queue[q_i].find { |x| x[:type] == -1 }
          cur_line ||= print_queue[q_i].find { |x| x[:type] == 1 }
          print_line(cur_line)
          printed[[q_i, cur_line[:type]]] = 1
          # puts "j: #{j}  q_i:#{q_i}  type:#{cur_line[:type]}   value:#{cur_line[:value]}"
          j += 1
        end
      end

      # puts "block:#{block}"
      # print "@@ #{block[:start_index]}, +#{block[:insertions]} -#{block_deletions} @@ ".light_blue
      # block[:block].each { |line| puts line[:value] }
      # puts
    end

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
