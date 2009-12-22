# Methods for cleaning Booleans
module BooleanHelper
  # Converts a string to a boolean where possible
  def get_b x
    return nil if x.nil?
    trues = ["yes", 'y',"1", 'true', 'optional']
    falses = ["no", 'n', "0", 'false']
    if trues.include? x.to_s.downcase.strip
      val = true
    elsif falses.include? x.to_s.downcase.strip
      val = false
    else
      val = nil
    end
    return val
  end
  
  # If any of the 'indicator properties' in the 
  # attribute hash are not nil, the boolean property
  # is set to true in the attribute hash. Otherwise 
  # it's set to the default (or not set if default=nil).
  # Returns the attribute hash.
  def infer_boolean bool_property, indicator_properties, atts, default=nil
    atts[bool_property] = default unless (atts[bool_property] or default.nil?)
    indicator_properties.each do |x|
      atts[bool_property] = true unless atts[x].nil?
    end
    return atts
  end
  
  # Cleans a list of Boolean values to be either true or false 
  def clean_bool dirty_vals
    vals = []
    (dirty_vals || '').split(@@sep).each { |dirty_val| 
      val = get_b(dirty_val)
      #if val.nil? and (!dirty_val.nil? and dirty_val.strip!='')
      #  val = dirty_val.match(/(not applicable|n\/a|not available)/i).nil?
      #end
      vals << val
    }
    if vals.empty? or vals.uniq == [nil]
      return nil
    elsif vals.include? true
      return true
    else
      return false
    end
  end
end 