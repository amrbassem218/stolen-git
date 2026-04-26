class Utils
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
end
