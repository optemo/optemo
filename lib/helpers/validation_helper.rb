module ValidationHelper
  
  def assert_all_valid model
    log_v "Not all #{model.name} valid" if model.valid.count < model.count
  end
  
  def assert_within_range reclist, att, min, max
    values = get_values reclist, att
    values.delete_if{|x,y| x.nil?}
    if values.keys.length == 0
      log_v "All values nil for #{reclist[0].type.to_s}'s #{att} attribute"
      return
    end
    outliers = values.reject{|x,y| (x < min || x > max) }
    log_v "Smallest #{att} below min for #{reclist[0].type.to_s}: #{values.keys.sort.first}" if values.keys.sort.first < min
    log_v "Largest #{att} above max for #{reclist[0].type.to_s}: #{values.keys.sort.last}" if values.keys.sort.last > max 
    log_v  "Outliers: #{outliers.collect{|x,y| y}*', '}" if outliers.size > 0 and outliers.size < 10
  end
  
  def assert_no_repeats reclist, att
    values = get_values reclist, att
    log_v " Repeated values in #{reclist.first.class}'s #{att}" if values.uniq.count != values.count
  end
  
  def assert_no_0_values reclist, att 
    values = get_values reclist, att
    outliers = values.reject{|x,y| x==0}
    log_v " There are 0s in #{reclist.first.class}'s #{att} " if outliers.size > 0
    log_v  "Outliers: #{outliers.collect{|x,y| y}*', '}" if outliers.size > 0  and outliers.size < 10
  end
  
  
  def assert_not_all_nils reclist, att 
    values = get_values reclist, att
    log_v " There are nils in #{reclist.first.class}'s #{att} " if values.keys.uniq == [nil]
  end
  
  def assert_no_nils reclist, att 
    values = get_values reclist, att
    outliers = values.reject{|x,y| x.nil?}
    log_v " There are nils in #{reclist.first.class}'s #{att} " if outliers.size > 0
    log_v "Outliers: #{outliers.collect{|x,y| y}*', '}" if outliers.size > 0 and outliers.size < 10
  end
  
  # TODO !!
  #def assert_not_both_nil reclist, firstatt, secondatt
  #end
  
  def assert_no_nils_or_0s_in_att reclist, att 
    assert_no_0_values reclist, att
    assert_no_nils reclist, att
  end
  
  # This is sort of a stupid method.
  # Should I move it somewhere else?
  def both_have_real_value_for_att rec1, rec2, att
    # All these checks!
    return false unless rec1.has_attribute? att 
    return false unless rec2.has_attribute? att
    return false if rec1.[](att).nil?
    return false if rec2.[](att).nil?
    return false if rec1.[](att).to_s.empty?
    return false if rec2.[](att).to_s.empty?
    return false if rec1.[](att).to_s.strip == ""
    return false if rec2.[](att).to_s.strip == ""
    return false if rec1.[](att) == 0
    return false if rec2.[](att) == 0
    return true
  end
  
  # Should be made private
  def get_values reclist, att
    values = reclist.inject({}) { |r,x| 
      r[x.[](att)]  = x.id
      r
    }
    return values
  end
  
  def log_v str
    printme  = " INVALID DATA :" + str
    @logfile.puts printme if @logfile
    puts printme  
  end
  
end