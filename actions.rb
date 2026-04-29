require 'securerandom'
require 'optparse'
require_relative 'differencing'
require_relative 'utils'
require 'fileutils'
require 'colorize'
require 'json'
module Actions
  include DiffCalc

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
      FileUtils.mkdir_p('.stolen-git/branches')

      FileUtils.mkdir_p('.stolen-git/storage')
      FileUtils.mkdir_p('.stolen-git/storage/blobs')
      FileUtils.mkdir_p('.stolen-git/storage/trees')

      # main files
      File.write('.stolen-git/project_info.json', {})
      File.write('.stolen-git/commits.json', JSON.pretty_generate({ commits: [] }))
      File.write('.stolen-git/index.json', {})

      main_branch_id = SecureRandom.uuid
      File.write(".stolen-git/branches/#{main_branch_id}.json",
                 JSON.pretty_generate({ name: 'main', last_edited: Time.now, commit_pointer: '' }))

      File.write('.stolen-git/pointer.json', JSON.pretty_generate({ current_branch: main_branch_id }))
      puts 'Stolen-git initialized Sucessfully :D'
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
    index = index.sort.to_h
    File.write('.stolen-git/index.json', JSON.pretty_generate(index))
  end

  def commit
    options = { name: '', description: '' }

    # Getting commit name & description
    OptionParser.new do |opts|
      opts.banner = 'Usage: stolen-git commit [options]'

      opts.on('-n', '--name NAME', 'Add a commit name') do |name|
        options[:name] = name
      end

      opts.on('-d', '--description DESCRIPTION', 'Add a commit description') do |description|
        options[:description] = description
      end
    end.parse!

    options[:name] = ask('Add a commit name: ') if options[:name].empty?

    # Get the index
    index = JSON.parse(File.read('.stolen-git/index.json'))
    tree_content = {
      entries: []
    }

    commit_history = JSON.parse(File.read('.stolen-git/commits.json'))

    pointer = read_json('.stolen-git/pointer.json')
    branch_id = pointer['current_branch']
    branch_content = read_json(".stolen-git/branches/#{branch_id}.json")
    parent_commit = branch_content['commit_pointer']

    # Getting differences to last commit

    no_insertions = 0
    no_deletions = 0
    no_file_changed = 0
    commit_diff = {}

    getting_diff = lambda do |entries|
      parent_index = 0

      index.each do |key, value|
        if entries && entries[parent_index] && key == entries[parent_index]['path']
          new_hash = value['hash']
          old_hash = entries[parent_index]['hash']
          parent_index += 1
          next if value['hash'] == new_hash

          entry_content = File.read(".stolen-git/storage/blobs/#{old_hash}").lines.to_a
          new_entry_content = File.read(".stolen-git/storage/blobs/#{new_hash}").lines.to_a
          compute_diff(entry_content, new_entry_content)
          diff = build_sequences
          no_insertions += diff[:insertions]
          no_deletions += diff[:deletions]
          no_file_changed += 1
          commit_diff[key] = diff
        else
          new_entry_content = File.read(".stolen-git/storage/blobs/#{value['hash']}").lines.to_a
          compute_diff('', new_entry_content)
          diff = build_sequences

          no_insertions += diff[:insertions]
          no_deletions += diff[:deletions]
          no_file_changed += 1
          commit_diff[key] = diff
        end
      end
    end

    if parent_commit.empty?
      getting_diff.call(nil)
    else
      parent_commit_content = read_json(".stolen-git/commits/#{parent_commit}.json")
      parent_tree_hash = parent_commit_content['tree_hash']
      parent_tree_content = JSON.parse(File.read(".stolen-git/storage/trees/#{parent_tree_hash}.json"))
      getting_diff.call(parent_tree_content['entries'])
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
    tree_content[:entries] = tree_content[:entries].sort { |a, b| a['path'] <=> b['path'] }
    tree_content = JSON.pretty_generate(tree_content)
    tree_hash = get_string_hash(tree_content)
    File.write(".stolen-git/storage/trees/#{tree_hash}.json", tree_content)

    # Making the commit
    # TODO: Change to actual values when personal profiles are created
    commit_id = SecureRandom.uuid
    commit_content = {
      tree_hash: tree_hash,
      created_at: Time.now,
      id: commit_id,
      parent_commit: parent_commit,
      author_profile: {
        name: 'Amr',
        email: 'amrbassem218@gmail.com',
        username: 'amrbassem218'
      },
      name: options[:name],
      description: options[:description],

      no_insertions: no_insertions,
      no_deletions: no_deletions,
      no_files_changed: no_file_changed
    }
    commit_content = JSON.pretty_generate(commit_content)
    commit_hash = get_string_hash(commit_content)
    File.write(".stolen-git/commits/#{commit_hash}.json", commit_content)

    # Adding commit to history
    commit_history['commits'].push({ id: commit_id, hash: commit_hash, name: options[:name] })
    File.write('.stolen-git/commits.json', JSON.pretty_generate(commit_history))

    # Adding to branch
    branch_content['commit_pointer'] = commit_hash
    File.write(".stolen-git/branches/#{branch_id}.json", JSON.pretty_generate(branch_content))

    # Print
    puts "#{no_file_changed} files changed, #{no_insertions} insertions(+), #{no_deletions} deletions(-)"
  end

  def reset
    commit_id = ARGV.first
    commit_history = read_json('.stolen-git/commits.json')
    pointer = read_json('.stolen-git/pointer.json')
    branch_id = pointer['current_branch']
    branch_content = read_json(".stolen-git/branches/#{branch_id}.json")
    current_commit_hash = if !commit_id || commit_id.empty?
                            branch_content['commit_pointer']
                          else
                            commit_history['commits'].values.find { |x| x['id'] == commit_id }['hash']
                          end

    parent_commit_hash = read_json(".stolen-git/commits/#{current_commit_hash}.json")['parent_commit']

    if parent_commit_hash.empty?
      puts "The current commit is the earliest in the project. Can't reset behind that."
      return
    end
    commit_content = read_json(".stolen-git/commits/#{parent_commit_hash}.json")
    commit_tree = read_json(".stolen-git/storage/trees/#{commit_content['tree_hash']}.json")
    index = read_json('.stolen-git/index.json')
    commit_tree['entries'].each do |entry|
      blob = File.read(".stolen-git/storage/blobs/#{entry['hash']}")
      # TODO: Figure out what to do when path changes
      File.write(entry['path'], blob)
      index[entry['path']]['hash'] = entry['hash']
      branch_content['commit_pointer'] = parent_commit_hash

      puts "entry_path: #{entry['path']}"
      puts "blob: #{blob}"
    end
    File.write('.stolen-git/index.json', JSON.pretty_generate(index))
    File.write(".stolen-git/branches/#{branch_id}.json", JSON.pretty_generate(branch_content))
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

  def log
    limit = ARGV.last
    limit = limit && !limit.empty? ? limit.to_i : 0
    commit_history_content = read_json('.stolen-git/commits.json')

    # puts "commits? #{commit_history_content['commits']}"
    commit_history_content['commits'].each_with_index do |commit, i|
      break if limit > 0 && i >= limit

      if limit == 0 && i >= 5
        q = ask(':')
        break if q == 'q'
      end
      commit_content = read_json(".stolen-git/commits/#{commit['hash']}.json")
      puts
      puts "commit #{commit_content['id']}".green
      puts "Author #{commit_content['author_profile']['username']} <#{commit_content['author_profile']['email']}>"
      puts "Date: #{commit_content['created_at']}"
      puts
      puts "    #{commit_content['name']}"
      puts
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
