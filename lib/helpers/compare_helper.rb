# The string/value comparison part of the cleaning helper
module CleaningHelper
  
  # Returns true if the strings are the same brand,
  # false otherwise
  def same_brand? one, two
    brands = [just_alphanumeric(one),just_alphanumeric(two)].uniq
    return false if brands.include?('') or brands.include?(nil)
    brands.sort!
    return true if brands.length == 1
    equivalent_list = [['hewlettpackard','hp'],['oki','okidata']]
    return true if equivalent_list.include?(brands)
    return false
  end
  
  # Returns the string in the array that is most 
  # likely to be a cartridge model?
  def get_most_likely_model arr, brand=''
    # TODO : cartridge model not just model. change method name!
    
    # Includes stuff between brackets too:
    arr_more = arr.collect{|x| [x, (x || '').match(/\(.*?\)/).to_s]}.flatten.reject{|x| x.nil? or x == ''}
    temp = arr_more.collect{|x| clean_model(x, brand)}
    arr_more += temp
    return arr_more.sort{|a,b| likely_to_be_cartridge_model_name(a) <=> likely_to_be_cartridge_model_name(b)}.last
  end
  
  # How likely is this to be a model name?
  def likely_model_name str
    score = 0
    return -10 if str.nil? or str.strip.length==0
  
    ja = just_alphanumeric(str)
    score += 1 if (ja.length < 17 and ja.length > 3)
    score += 1 if (ja.length < 11 and ja.length > 4)
    score += 1 if (ja.length < 9 and ja.length > 5)
    
    score -= 2 if str.match(/[0-9]/).nil?
    str.split(/\s/).each{|x| score -= 1 if(x.match(/[0-9]/).nil?)}
    score -= 2 if str.match(/,|\./)
    score -= 1 if str.match(/for/)
    score -= 3 if str.match(/\(|\)/)
    score -= 5 if str.match(/(series|and|&)\s/i)
  
    return score
  end

end