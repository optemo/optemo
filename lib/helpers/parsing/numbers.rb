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
  
end