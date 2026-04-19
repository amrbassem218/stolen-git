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

class DiffCalc
  attr_reader :mem, :cnt

  def initialize
    @mem = {}
    @cnt = 1
  end

  def differencing(old_s, new_s, i1, i2)
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

        isAdd = path == add
        insertions = isAdd ? path[:insertions] + 1 : path[:insertions]
        deletions = isAdd ? path[:deletions] : path[:deletions] + 1

        insertion_seq = path[:insertion_seq].dup
        deletion_seq = path[:deletion_seq].dup
        if isAdd
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

when 'test'
  s1 = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
  # s2 = "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like)."
  s2 = "alksfjlkasdjflkasdjflkasdj fasjflk;asdjflk aslfkjasdlkf jslkdfj j fjjfjf f f f f f f f f fpsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
  calc = DiffCalc.new
  # s1 = 'abcd'
  # s2 = 'aabcd'

  tests = ARGV
  puts "tests: #{tests}"
  if tests && tests.length >= 2
    s1 = tests[0]
    s2 = tests[1]
  end

  puts ''

  print s1
  puts

  puts '***b***'
  print s2
  puts
  diff = calc.differencing(s1, s2, 0, 0)

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
