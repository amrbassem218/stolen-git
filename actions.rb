require 'securerandom'
require_relative 'differencing'
require_relative 'utils'
require 'fileutils'
require 'json'
module Actions
  include DiffCalc
  def initialize
    @staged_default = { general_info: {}, files: {} }
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
      # main dot directory
      FileUtils.mkdir_p('.stolen-git')

      # Sub Directories
      FileUtils.mkdir_p('.stolen-git/commits')

      FileUtils.mkdir_p('.stolen-git/storage')
      FileUtils.mkdir_p('.stolen-git/storage/blobs')
      FileUtils.mkdir_p('.stolen-git/storage/trees')

      # main files
      File.write('.stolen-git/project_info.json', {})
      File.write('.stolen-git/commits.json', JSON.pretty_generate({ commits: [] }))
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

    index = JSON.parse(File.read('.stolen-git/index.json'))
    files.each do |file_path|
      file_hash = get_file_hash(file_path)
      file_content = File.read(file_path)

      next if index[file_path] && index[file_path]['hash'] == file_hash

      # Create blob
      File.write(".stolen-git/storage/blobs/#{file_hash}", file_content)

      # Assign index_obj
      default_index_obj = {}
      index[file_path] ||= default_index_obj
      index[file_path]['hash'] = file_hash
    end
    File.write('.stolen-git/index.json', JSON.pretty_generate(index))
  end

  def commit
    # Get the staged
    index = JSON.parse(File.read('.stolen-git/index.json'))
    tree_content = {
      entries: []
    }

    commit_history = JSON.parse(File.read('.stolen-git/commits.json'))
    parent_commit_exists = commit_history['commits'].length.positive?

    # Getting differences to last commit
    no_insertions = 0
    no_deletions = 0
    no_file_changed = 0
    parent_commit_hash = ''
    commit_diff = {}

    if parent_commit_exists
      parent_commit = commit_history['commits'].last
      parent_commit_hash = parent_commit['hash']

      parent_commit_content = JSON.parse(File.read(".stolen-git/commits/#{parent_commit_hash}.json"))
      parent_tree_hash = parent_commit_content['tree_hash']
      parent_tree_content = JSON.parse(File.read(".stolen-git/storage/trees/#{parent_tree_hash}.json"))
      parent_tree_content['entries'].each do |entry|
        # TODO: Handle when path changes across commits
        new_hash = index[entry['path']]['hash']
        is_equal = entry['hash'] == new_hash
        next if is_equal

        entry_content = File.read(".stolen-git/storage/blobs/#{entry['hash']}").lines.to_a
        new_entry_content = File.read(".stolen-git/storage/blobs/#{new_hash}").lines.to_a
        compute_diff(entry_content, new_entry_content)
        diff = build_sequences
        no_insertions += diff[:insertions]
        no_deletions += diff[:deletions]
        no_file_changed += 1
        commit_diff[entry[:path]] = diff
        # blob = File.read()
      end
    else
      index.each do |key, value|
        new_entry_content = File.read(".stolen-git/storage/blobs/#{value['hash']}").lines.to_a
        compute_diff('', new_entry_content)
        diff = build_sequences

        no_insertions += diff[:insertions]
        no_deletions += diff[:deletions]
        no_file_changed += 1
        commit_diff[key] = diff
      end
    end

    if no_file_changed <= 0
      puts 'Everything up to date'
      puts "If you have changed please 'stolen-git stage' them first "
      return
    end

    # Making the tree
    index.each do |key, value|
      tree_content[:entries].push({
                                    path: key,
                                    type: 'blob',
                                    hash: value['hash'],
                                    diff: commit_diff[key] || {}
                                  })
    end
    tree_content = JSON.pretty_generate(tree_content)
    tree_hash = get_string_hash(tree_content)
    File.write(".stolen-git/storage/trees/#{tree_hash}.json", tree_content)

    # Making the commit
    # TODO: Change to actual values when personal profiles are created
    commit_name = 'test_commit_1'
    commit_description = 'lorem20'
    commit_id = SecureRandom.uuid
    commit_content = {
      tree_hash: tree_hash,
      created_at: Time.now,
      commit_id: commit_id,
      parent_commit: parent_commit_hash,
      author_profile: {
        name: 'Amr',
        email: 'amrbassem218@gmail.com',
        username: 'amrbassem218'
      },
      name: commit_name,
      description: commit_description,

      no_insertions: no_insertions,
      no_deletions: no_deletions,
      no_files_changed: no_file_changed
    }
    commit_content = JSON.pretty_generate(commit_content)
    commit_hash = get_string_hash(commit_content)
    File.write(".stolen-git/commits/#{commit_hash}.json", commit_content)

    # Adding commit to history
    commit_history['commits'].push({ id: commit_id, hash: commit_hash, name: commit_name })
    File.write('.stolen-git/commits.json', JSON.pretty_generate(commit_history))

    # Print
    puts "#{no_file_changed} files changed, #{no_insertions} insertions(+), #{no_deletions} deletions(-)"
  end

  def reset
    commit_id = ARGV.first
    commit_history = read_json('.stolen-git/commits.json')
    commit_hash = if commit_id.empty?
                    commit_history['commits'].last['hash']
                  else
                    commit_history['commits'].values.find { |x| x['id'] == commit_id }
                  end
    commit_content = read_json(".stolen-git/commits/#{commit_hash}.json")
    commit_tree = read_json(".stolen-git/storage/trees/#{commit_content['tree_hash']}.json")
    commit_tree['entries'].each do |entry|
      File.read(".stolen-git/storage/blobs/#{entry['hash']}")
    end
  end

  def diff
    files = ARGV
    if files.length < 2
      puts 'Usage: stolen-git diff <first_file> <second_file>'
    else
      file_a = File.read(files[0]).split("\n")
      file_b = File.read(files[1]).split("\n")
      print_diff(file_a, file_b)
    end
  end

  # testers
  def check_router
    router = JSON.parse(File.read('.stolen-git/router.json'))
    keys = router.keys
    keys.each do |key|
      file_path = get_file_from_hash(key, './test')
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
