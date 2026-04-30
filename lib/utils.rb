require 'fileutils'
require 'optparse'
require 'digest'
module Utils
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

  def ask(prompt)
    print prompt
    gets.chomp
  end

  def get_string_hash(str)
    Digest::SHA256.hexdigest(str)
  end

  def read_json(path)
    JSON.parse(File.read(path))
  end

  def get_file_hash(path)
    Digest::SHA256.file(path).hexdigest
  end

  def get_file_from_hash(hash, dir_path)
    Dir.glob("#{dir_path}/**/*").each do |file_path|
      next unless File.file?(file_path)

      file_hash = get_file_hash(file_path)
      return file_path if file_hash == hash
    end
    nil
  end

  def revert_to_commit(commit_hash)
    commit_content = read_json(".stolen-git/commits/#{commit_hash}.json")
    commit_tree = read_json(".stolen-git/storage/trees/#{commit_content['tree_hash']}.json")
    index = {}
    commit_tree['entries'].each do |entry|
      blob = File.read(".stolen-git/storage/blobs/#{entry['hash']}")
      # TODO: Figure out what to do when path changes
      File.write(entry['path'], blob)
      index[entry['path']] ||= {}
      index[entry['path']]['hash'] = entry['hash']
    end

    File.write('.stolen-git/index.json', JSON.pretty_generate(index))
  end
end

include Utils
