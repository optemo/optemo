module DataValidator
  # If asserts are not true:
  # Logs to @logfile and $logfile if either
  # is present; prints to screen as well.
  
  # Are all the entries valid? 
  def assert_all_valid model
    log_v "Not all #{model.name} valid" if model.valid.count < model.count
  end
  
  # Is the attribute between min and max for the 
  # given list of database entries (records)?
  def assert_within_range reclist, att, min, max
    values = get_values reclist, att
    values.delete_if{|x,y| y.nil?}
    if values.values.length == 0
      log_v "All values nil for #{reclist[0].type.to_s}'s #{att} attribute"
      return
    end
    outliers = values.reject{|k,v| (v >= min and v <= max) }
    sorted_values = values.values.sort
    if outliers.size > 0
      announce 'INVALID DATA:'
      announce "#{outliers.size} invalid #{att}s."
      announce  "Outliers: #{outliers.collect{|x,y| x}*', '}" if outliers.size < 10
      if sorted_values.first < min
        lowest = sorted_values.first
        temp = sorted_values.reject{|x| x > lowest}.count
        temp2 = sorted_values.reject{|x| x > min}.count
        announce "Smallest #{att} below min: #{lowest}. # records w/ this value: #{temp}" 
        announce " # records below min : #{temp2}" 
      end
      if sorted_values.last > max 
        highest = sorted_values.last
        temp = sorted_values.reject{|x| x < highest}.count
        temp2 = sorted_values.reject{|x| x < max}.count
        announce "Largest #{att} above max: #{highest}. # records w/ this value: #{temp}" 
        announce " # records above max: #{temp2}"
      end
      announce '------'
    else 
      announce "Valid data for #{att}!"
    end
  end
  
  # Does the attribute have duplicates
  # within the dataset (reclist)?
  def assert_no_repeats reclist, att
    values = get_values reclist, att
    uniques = values.values.uniq
    log_v "Repeated values in #{reclist.first.class}'s #{att}" if uniques.count != values.count
  end
  
  
  # The attribute should have no values = 0
  # in the given data set
  def assert_no_0_values reclist, att 
    values = get_values reclist, att
    outliers = values.reject{|x,y| x != 0}
    log_v " There are #{outliers.size} 0s in #{reclist.first.class}'s #{att} " if outliers.size > 0
    log_v  "Outliers: #{outliers.collect{|x,y| x}*', '}" if outliers.size > 0  and outliers.size < 10
  end
  
  # Is there at least one non-nil value in the data set?
  def assert_not_all_nils reclist, att 
    values = get_values reclist, att
    log_v " There are nils in #{reclist.first.class}'s #{att} " if values.values.uniq == [nil]
  end
  
  # The attribute should have no nil values
  # in the given data set
  def assert_no_nils reclist, att 
    values = get_values reclist, att
    outliers = values.reject{|x,y| !y.nil? }
    log_v " There are #{outliers.size} nils in #{reclist.first.class}'s #{att} " if outliers.size > 0
    log_v "Outliers: #{outliers.collect{|x,y| x}*', '}" if outliers.size > 0 and outliers.size < 10
  end
  
  # Does the attribute have either nils
  # or zeroes as value in the given data set?
  def assert_no_nils_or_0s_in_att reclist, att 
    assert_no_0_values reclist, att
    assert_no_nils reclist, att
  end

  def assert_no_empty_values reclist, att # No 0s, no blanks, no nils
    counter = 0
    reclist.each do |rec|
      counter += 1 unless has_real_value_for_att(rec, att)
    end
    log_v "#{counter} records have an empty #{att}" if counter != 0
  end

  def has_real_value_for_att rec, att
    return false unless rec.has_attribute? att 
    return false if rec.[](att).nil?
    return false if rec.[](att).to_s.empty?
    return false if rec.[](att).to_s.strip == ""
    return false if rec.[](att) == 0
    return true
  end

  def both_have_real_value_for_att rec1, rec2, att
    return false unless has_real_value_for_att(rec1, att)
    return false unless has_real_value_for_att(rec2, att)
    return true
  end
  
  def get_values reclist, att
    values = reclist.inject({}) { |r,x| 
      r[x.id]  = x.[](att)
      r
    }
    return values
  end
end