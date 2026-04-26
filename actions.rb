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
      FileUtils.mkdir_p('.stolen-git/last')

      # main files
      File.write('.stolen-git/router.json', {})
      File.write('.stolen-git/project_info.json', {})
      File.write('.stolen-git/commits.json', [])
      File.write('.stolen-git/staged.json', JSON.pretty_generate(@staged_default))

      puts "#{NAME.capitalize} initialized Sucessfully :D"
    end
  end

  def stage
    files = ARGV
    if files.empty?
      puts 'Usage: stolen-git stage <files..>'
      return
    end
    staged = JSON.parse(File.read('.stolen-git/staged.json'), symbolize_names: true)

    router_path = '.stolen-git/router.json'
    router = JSON.parse(File.read(router_path))
    diff_calc = DiffCalc.new

    files.each do |file_path|
      file_hash = UTILS.get_file_hash(file_path)
      file_content = File.read(file_path)

      if router[file_hash]
        old_file_path = ".stolen-git/last/#{router[file_hash]}"
        old_content = File.read(old_file_path)
        next if old_content == file_content

        diff_calc.compute_diff(old_content.lines.to_a, file_content.lines.to_a)

        # Updating reference file
        File.write(old_file_path, file_content)
      else
        ext = File.extname(file_path)
        stage_id = SecureRandom.uuid
        new_name = "#{stage_id}#{ext}"

        # Creating reference files
        File.write(".stolen-git/last/#{stage_id}#{ext}", file_content)

        # Updating router
        router[file_hash] = new_name
        File.write(router_path, JSON.pretty_generate(router))

        diff_calc.compute_diff([], file_content.lines.to_a)
      end

      diff = diff_calc.build_sequences
      staged[:files][file_hash] = {
        name: File.basename(file_path),
        **diff
      }
      staged[:general_info][:insertions] ||= 0
      staged[:general_info][:insertions] += diff[:insertions]

      staged[:general_info][:deletions] ||= 0
      staged[:general_info][:deletions] += diff[:deletions]
    end

    File.write('.stolen-git/staged.json', JSON.pretty_generate(staged))
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
