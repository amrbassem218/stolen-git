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
end
