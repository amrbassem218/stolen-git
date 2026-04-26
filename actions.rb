require 'securerandom'
require_relative 'differencing'
require_relative 'utils'
require 'fileutils'
require 'json'
UTILS = Utils.new
class Actions
  def initialize
    @staged_default = { general_info: {}, files: {} }
  end

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
      FileUtils.mkdir_p('.stolen-git/blobs')

      # main files
      File.write('.stolen-git/project_info.json', {})
      File.write('.stolen-git/commits.json', [])
      File.write('.stolen-git/index.json', {})

      puts "#{NAME.capitalize} initialized Sucessfully :D"
    end
  end

  def stage
    files = ARGV
    if files.empty?
      puts 'Usage: stolen-git stage <files..>'
      return
    end

    index = JSON.parse(File.read('.stolen-git/index.json'), symbolize_names: true)
    files.each do |file_path|
      file_hash = UTILS.get_file_hash(file_path)
      file_content = File.read(file_path)
      file_name = File.basename(file_path)

      # Create blob
      File.write(".stolen-git/blobs/#{file_hash}.json", file_content)

      # Update Index

      # Assign index_obj
      default_index_obj = {}
      index[file_name] ||= default_index_obj
      index[file_name][:hash] = file_hash
    end
    File.write('.stolen-git/index.json', JSON.pretty_generate(index))
  end

  def commit
    # Get the staged
    staged = JSON.parse(File.read('.stolen-git/staged.json'), symbolize_names: true)

    if staged == @staged_default

      puts "There are no staged files please run 'stolen-git stage <file>' first"

    else
      commit_id = SecureRandom.uuid
      path = ".stolen-git/commits/#{commit_id}.json"

      # Create a commit file
      File.write(path, JSON.pretty_generate(staged))

      # Add the commit to the commit history
      commit_history = JSON.parse(File.read('.stolen-git/commits.json'))
      commit_history.push({ commit_id: 'nameless for now', created_at: Time.now, id: commit_id, path: path })
      File.write('.stolen-git/commits.json', JSON.pretty_generate(commit_history))

      # reset the stage
      File.write('.stolen-git/staged.json', JSON.pretty_generate(@staged_default))

      # print
      no_files_changed = staged[:files].keys.length
      no_insertions = staged[:general_info][:insertions]
      no_deletions = staged[:general_info][:deletions]
      puts "#{no_files_changed} files changed, #{no_insertions} insertions(+), #{no_deletions} deletions(-)"
    end
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

  # testers
  def check_router
    router = JSON.parse(File.read('.stolen-git/router.json'), symbolize_names: true)
    keys = router.keys
    keys.each do |key|
      file_path = UTILS.get_file_from_hash(key, './test')
      puts file_path || "Couldn't fine file path from this path"
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
end
