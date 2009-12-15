#NUMBERS CLEANING
#   get_i str
#   (deprecate) proper_start str
#   get_f str
#   get_el x
#   clean_bool dirty_vals
#   self.float_rxp
#   get_max_f str
#   maxres_from_res res
#   get_f_with_units str, unit_regex
#   get_f_with_units_in_front str, unit_regex
#   float_and_regex x
#   append_regex x, y

module NumberParser
  
  @@float_rxp = /(\d+,)?\d+(\.\d+)?/
  
  def self.float_rxp
    return @@float_rxp
  end
  
  
  # Returns the first integer in the string, or null
  def get_i str
    return nil if str.nil? or str.empty?
    return str.strip.match(/(\d+,)?\d+/).to_s.gsub(/,/,'').to_i
  end
  
  # Returns the first float in the string, or null
  # Eliminates thousand-separating commas
  def get_f str
    return nil if str.nil? or str.empty?
    myfloat =  str.strip.match(/(\d+,)?\d+(\.\d+)?/).to_s.gsub(/,/,'').to_f
    return nil if myfloat == 0 
    return myfloat
  end
  
  
  # Gets the max float from a string
  def get_max_f str
    return nil if str.nil?
    strsplit = str.split(/[\s-]/).collect{|x| get_f x}.delete_if{|x| x.nil?}.sort
    myfloat =  strsplit.last if strsplit
    return myfloat
  end
  
  
  # Gets the min float from a string
  def get_min_f str
    return nil if str.nil?
    strsplit = str.split(/[\s-]/).collect{|x| get_f x}.delete_if{|x| x.nil? or x == 0}.sort
    myfloat =  strsplit.first if strsplit
    return myfloat
  end

  
  # Gets a float with given units from a string
  def get_f_with_units str, unit_regex
    return (get_f str.match(float_and_regex(unit_regex)).to_s) 
  end
  
  # Gets a float with given units from a string
  def get_f_with_units_in_front str, unit_regex
    return (get_f str.match(append_regex( unit_regex, @@float_rxp)).to_s) 
  end
  
  # Adds on a regular expression to the regex for a float.
  def float_and_regex x
    return append_regex @@float_rxp, x
  end
  
  # Glues two regexes together side by side
  def append_regex x, y
    z = x.to_s + y.to_s
    return Regexp.new(z)
  end
  
end