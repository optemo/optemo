module DataValidityAnalyzer
  
  def count_not_in_range reclist, att, min, max
    out_of_range = reclist.reject{|x| x[att].nil? or (x[att] >= min and x[att] <= max) }.count
    return out_of_range
  end
  
  def count_not_in_set reclist, att, set
    not_in_set = reclist.reject{|x| x[att].nil? or set.include?(x[att]) }.count
    return not_in_set
  end
  
  # The attribute should have no values = 0
  # in the given data set
  def count_0_values reclist, att 
    num_zeros = reclist.reject{|x| x[att].nil? or x[att] != 0}.count
    return num_zeros
  end
  
  def count_nils reclist, att 
    num_zeros = reclist.reject{|x| !x[att].nil?}.count
    return num_zeros
  end
  
end