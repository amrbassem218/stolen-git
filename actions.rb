require 'securerandom'
require_relative 'differencing'
require_relative 'utils'
require 'fileutils'
require 'json'
UTILS = Utils.new
class Actions
  def p_initialize
    # Check if already initialized
    if File.exist?('.stolen-git')
      if UTILS.confirm?('An instance of stolen-git is already up here do you want to replace it')
        if UTILS.confirm?('THIS WILL DELETE ALL COMMITS AND INSTANCES OF stolen-git. ARE YOU SURE')
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
      # main dot directory
      FileUtils.mkdir_p('.stolen-git')

      # Sub Directories
      FileUtils.mkdir_p('.stolen-git/commits')
      FileUtils.mkdir_p('.stolen-git/last')

      # main files
      File.write('.stolen-git/router.json', {})
      File.write('.stolen-git/project_info.json', {})
      File.write('.stolen-git/commits.json', [])
      File.write('.stolen-git/staged.json', JSON.pretty_generate({ general_info: {}, files: {} }))

      puts "#{NAME.capitalize} initialized Sucessfully :D"
    end
  end

  def check_router
    router = JSON.parse(File.read('.stolen-git/router.json'), symbolize_names: true)
    keys = router.keys
    keys.each do |key|
      file_path = UTILS.get_file_from_hash(key, './test')
      puts file_path || "Couldn't fine file path from this path"
    end
  end

  def stage
    files = ARGV
    if files.empty?
      puts 'Usage: stolen-git stage <files..>'
      return
    end
    staged = JSON.parse(File.read('.stolen-git/staged.json'), symbolize_names: true)
    files.each do |file_path|
      file_hash = UTILS.get_file_hash(file_path)
      router_path = '.stolen-git/router.json'
      router = JSON.parse(File.read(router_path), symbolize_names: true)
      diff_calc = DiffCalc.new
      file_content = File.read(file_path)
      if router[file_hash]
        old_file_path = ".stolen-git/last/#{router[file_hash]}"
        old_content = File.read(".stolen-git/last/#{old_file_path}")
        diff_calc.compute_diff(old_content.lines.to_a, file_content.lines.to_a)
        File.write(old_file_path, file_content)
      else
        ext = File.extname(file_path)
        name = SecureRandom.uuid
        new_name = "#{name}#{ext}"
        File.write(".stolen-git/last/#{name}#{ext}", file_content)
        router[file_hash] = new_name
        File.write(router_path, JSON.pretty_generate(router))
        diff_calc.compute_diff([], file_content.lines.to_a)
      end
      diff = diff_calc.build_sequences
      staged[:files][file_hash] = JSON.pretty_generate(
        {
          name: File.basename(file_path, '.*'),
          diff: diff
        }
      )
      staged[:general_info][:insertions] ||= 0
      staged[:general_info][:insertions] += diff[:insertions]

      staged[:general_info][:deletions] ||= 0
      staged[:general_info][:deletions] += diff[:deletions]
    end
    File.write('.stolen-git/staged.json', JSON.pretty_generate(staged))
    puts '*******'
    puts staged
  end

  def test
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
  end

  def diff
    files = ARGV
    if files.length < 2
      puts 'Usage: stolen-git diff <first_file> <second_file>'
    else
      file_a = File.read(files[0]).split("\n")
      file_b =  File.read(files[1]).split("\n")
      diff_calc = DiffCalc.new
      diff_calc.print_diff(file_a, file_b)
    end
  end
end
