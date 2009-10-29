module CleaningHelper
  
  def vote(array)
    count_votes = array.inject({}){ |r,x| r.merge( x=>(1+(r[x]||0))) }
    return nil if count_votes.length == 0
    winner = count_votes.to_a.sort{|x,y| y[1]<=>x[1]}.first[0]
    return winner
  end
  
  def mean(array)
    return array.inject(0){ |r,x| r + x.to_f }/array.size.to_f
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
  
  # Returns the price integer: float * 100, rounded
  def get_price_i price_f
    return nil if price_f.nil? 
    return (price_f * 100).round
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
end