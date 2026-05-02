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
                 JSON.pretty_generate({ name: 'main', created_at: Time.now, commit_pointer: '' }))

      File.write('.stolen-git/pointer.json', JSON.pretty_generate({ point_to: main_branch_id, type: 'branch' }))
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
    branch_id = pointer['point_to']
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
      puts "If you have changed please 'stg stage' them first "
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
      branch_id: branch_id,
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
    branch_id = pointer['point_to']
    branch_content = read_json(".stolen-git/branches/#{branch_id}.json")
    current_commit_hash = branch_content['commit_pointer']

    new_commit = if !commit_id || commit_id.empty?
                   current_commit_hash
                 else
                   commit_history['commits'].find do |x|
                     x['id'] == commit_id
                   end['hash']
                 end

    if new_commit.empty?
      puts "This commit doesn't exit"
      return
    end

    revert_to_commit(new_commit)
    branch_content['commit_pointer'] = new_commit
    File.write(".stolen-git/branches/#{branch_id}.json", JSON.pretty_generate(branch_content))
  end

  def checkout
    options = { commit: false }

    # Getting commit name & description
    OptionParser.new do |opts|
      opts.banner = 'Usage: stolen-git checkout [options]'

      opts.on('-c', '--commit', 'Add a commit id instead') do
        options[:commit] = true
      end
    end.parse!
    inp = ARGV.last
    if !inp
      puts 'Please Enter the name of a branch or commit_id'
    elsif options[:commit]
      commit_history = read_json('.stolen-git/commits.json')
      current_commit_hash = commit_history['commits'].find { |x| x['id'] == inp }['hash']
      revert_to_commit(current_commit_hash)
    else
      # TODO: Handle if user enters branch_id instead
      branch_content = {}
      branch_id = ''
      Dir.children('.stolen-git/branches').each do |entry|
        branch_content = read_json(".stolen-git/branches/#{entry}")
        if branch_content['name'] == inp
          branch_id = File.basename(entry, '.*')
          break
        end
      end
      if branch_content.empty?
        puts 'There is no branch with that name.'
        nil
      end
      commit_hash = branch_content['commit_pointer']
      revert_to_commit(commit_hash)
      pointer = read_json('.stolen-git/pointer.json')
      pointer['point_to'] = branch_id
      pointer['type'] = 'branch'
      File.write('.stolen-git/pointer.json', JSON.pretty_generate(pointer))
    end
  end

  def branch
    name = ARGV.last
    pointer = read_json('.stolen-git/pointer.json')
    pointed_branch = pointer['type'] == 'branch' ? pointer['point_to'] : ''
    if name
      first_commit = pointer['type'] == 'branch' ? read_json(".stolen-git/branches/#{pointed_branch}.json")['commit_pointer'] : pointer['point_to']
      id = SecureRandom.uuid
      File.write(".stolen-git/branches/#{id}.json", JSON.pretty_generate({
                                                                           name: name,
                                                                           created_at: Time.now,
                                                                           commit_pointer: first_commit
                                                                         }))
      return
      puts "branch #{name} created"
    end
    Dir.children('.stolen-git/branches').each do |entry|
      branch_content = read_json(".stolen-git/branches/#{entry}")
      branch_id = File.basename(entry, '.*')
      if pointed_branch == branch_id
        print '* '
        puts "#{branch_content['name']}".green
      else
        puts "#{branch_content['name']}"
      end
    end
  end

  def diff
    index = read_json('.stolen-git/index.json')
    index.each do |key, value|
      new_file_content = File.exist?(key) ? File.read(key) : nil
      file_name = File.basename(key)
      if new_file_content.nil?
        print "@@#{file_name}".cyan
        print " [DELETED]]\n".red
      else
        new_hash = get_file_hash(key)
        next if new_hash == value['hash']

        print "@@#{file_name}".cyan
        blob_content = File.read(".stolen-git/storage/blobs/#{value['hash']}")
        print_diff(blob_content, new_file_content)
      end
    end
  end

  def log
    limit = ARGV.last
    limit = limit && !limit.empty? ? limit.to_i : 0
    commit_history_content = read_json('.stolen-git/commits.json')

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
end
