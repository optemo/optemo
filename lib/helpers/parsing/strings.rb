module StringCleaner
  
  # Takes out any characters that are not alphanumeric. Spaces too.
  def just_alphanumeric label
   return nil if label.nil?
    return label.downcase.gsub(/ /,'').gsub(/[^a-zA-Z 0-9]/, "")
  end
  
  # Takes out stuff inside html-style tags.
  def no_tags label
    return label.gsub(/\<.+\/?\>/,'')
  end
  
  # Removes all leading & trailing spaces
  # Deals with weirdness found on TigerDirect website
  def no_leading_spaces str
    return str.gsub(/\302\240/,'').strip # What a hack.
  end
  
  # If your string starts with a number it puts an
  # underscore (column names can't start with #s)
  def proper_start str
    return "_#{str}" if str.match(/^[0-9]/) 
    return str
  end
  
  def no_blanks array
    return array.reject{|x| x.nil? or x.to_s.strip == ''}
  end
  
end