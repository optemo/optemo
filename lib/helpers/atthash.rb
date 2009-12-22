# The atthash is a mapping of attribute name to value,
# used throughout the cleaning code. It is convenient 
# because it is similar in structure to the output from
# our table scraping method.
# This module contains methods useful in manipulating 
# the atthash, but unrelated to parsing data.
module AtthashHelper
  
  @@sep = '!@!'
  
  def self.sep 
    return @@sep
  end
  
  # Merges all the values from several fields to a new field
  def multiple_fields_to_one multfields, prefix=false
      vals = []
      multfields.each do |field, anotherval|
         if anotherval and not anotherval.empty? 
           anotherval = anotherval.strip
           anotherval = field + ": #{anotherval}" if prefix
           vals << anotherval
         end 
      end
      vals.delete_if {|x| x.empty?}
      return vals * ", " unless vals.empty?
      return nil
  end
  
  def separate string
    array = string.split("#{@@sep}").reject{|x| x.nil? or x == ''}
    return array
  end
  
  def combine_for_storage array
    string = array.reject{|x| x.nil? or x == ''}.join("#{@@sep}")
    return string
  end
  
  def combine_for_reading array
    string = array.reject{|x| x.nil? or x == ''}.collect{|x| x.strip}.uniq.join(", ")
    return string
  end
  
  def remove_sep! atts
    atts.each{|x,y| atts[x] = combine_for_reading(separate(y)) if y.type == String }
  end
  
  def remove_blank_strings! atts
    atts.each { |x,y| atts[x] = nil if y and y == '' }
  end
  
  def all_vals_to_s! hash
    temp = hash.keys
    temp.each{|k| hash[k] = hash[k].to_s}
  end
  
end