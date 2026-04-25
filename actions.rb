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
      File.write('.stolen-git/staged.json', [])

      puts "#{NAME.capitalize} initialized Sucessfully :D"
    end
  end

  def stage
    files = ARGV
    puts files
    if files.empty?
      puts 'Usage: stolen-git stage <files..>'
      return
    end
    files.each do |file|
      file_hash = UTILS.get_file_hash(file)
      router_path = '.stolen-git/router.json'
      router = File.read(router_path)
      puts "'Router not found. run 'stolen-git init' to reinitialize " if router.empty?
      router = JSON.parse(router)
      puts "router: #{router}"
      if router[file_hash]
        # klasdfj
      else
        ext = File.extname(file)
        name = SecureRandom.uuid
        file_content = File.read(file)
        File.write(".stolen-git/last/#{name}#{ext}", file_content)

      end
    end
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
