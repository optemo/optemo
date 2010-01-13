module DimensionsHelper
  #LENGTHS/WEIGHTS
  
  @@dimensions = {'D' => 'itemlength', 'W' =>'itemwidth', 'H' =>'itemheight'}
  
  # Converts metric length(array: [m,cm,mm]) to cm
  def to_cm length
    return nil if (length.nil? or length.size < 3)
    return length[0]*100 + length[1] + length[2]/10
  end
  
  # Gets metric length (array: [m,cm,mm]) from a string
  def parse_metric_length str
    return nil if (str.nil? or str=='')
    mm = get_f_with_units( str,  /(\s)m(illi)?m(et(er|re)(s)?)?/i ) || 0
    cm = get_f_with_units( str, /(\s)c(enti)?m(et(er|re)(s)?)?/i ) || 0
    m = get_f_with_units( str,  /(\s)m(et(er|re)(s)?)?/i ) || 0
    
    return [m, cm, mm] unless [m, cm, mm].uniq == [0]
    return nil
  end
  
  # Gets a number associated with units of inches from a string.
  def get_inches str
    return nil unless str
    inches = get_f_with_units( str,  /(\s|-)?(in(ch(es)?)? |\")/i )
    return nil unless (inches and inches > 0)
    return inches
  end
  
  # Returns [WIDTH, DEPTH, HEIGHT]
  def parse_metric_dimensions str
    return nil if (str.nil? or str=='')
    dims = [nil,nil,nil]
    str.split('x').each do |dim|
      dim_cm = to_cm(parse_metric_length(dim))
      if (dim_cm != 0)
        dims[0] = dim_cm if dim.match(/w/i) 
        dims[1] = dim_cm if dim.match(/[dl]/i)
        dims[2] = dim_cm if dim.match(/h/i)  
      end
    end
    return dims unless dims.uniq == [nil]
    return nil
  end
  
  # Gets weight from a string. If it is imperial it'll be an array 
  # with length 2 ([pounds,ounces]) and if its metric it'll be an 
  # array with length 3([kg, g, mg]).
  def parse_weight str
    return nil unless str
    # TODO
    # Metric
    kg = get_f_with_units( str,  /(\s)?k(ilo)?g(ram(s)?)?/i ) || 0
    g = get_f_with_units( str, /(\s)?g(ram(s)?)?/i ) || 0
    mg = get_f_with_units( str,  /(\s)?m(illi)?g(ram(s)?)?/i ) || 0
    # Imperial
    lbs = get_f_with_units( str, /(\s)?(lb(s)?|p(oun)?d(s)?)/i ) || 0
    oz = get_f_with_units( str,  /(\s)?o(unce(s)?|z)/i ) || 0
    return [kg,g,mg] if (kg !=0 or g !=0 or mg !=0)
    return [lbs,oz]  if (lbs !=0 or oz !=0)
    return nil 
  end
  
  def to_pounds parsed
    return nil if parsed.nil?
    wt = 0
    if parsed.length == 3
      wt = (to_grams(parsed))/453.5  # 453.5 grams = 1 lb
    elsif parsed.length == 2
      wt = parsed[0]+(parsed[1]/16)
    end
    return wt unless wt == 0
    return nil 
  end
  
  # Converts metric weight array([kg,g,mg]) to grams
  def to_grams wt
    return nil if wt.nil? or wt.length ==2
    return (wt[0]*1000+wt[1]+wt[2]/1000)
  end
  
  def rearrange_dims! atts, order, harsh=false
    dims = @@dimensions.collect{|k,v| get_i(atts[v]) || 0}
    #debugger if dims.include?(0) and harsh and dims.uniq.length > 1
    clear_dims!(atts) if dims.include?(0) and harsh
    return atts if dims.include?(0)
    dims.sort!
    order.each_with_index do |whichdim, index|
      atts[@@dimensions[whichdim]] = dims[index].to_s
    end
  end
  
  def clear_dims! atts
    @@dimensions.values.each do |dimname|
      atts[dimname] = nil
    end
  end
  
  def clean_dimensions dimensions_array, factor=100
    dimensions_data = dimensions_array.collect{ |x| 
      x.gsub(/''/, '\"').gsub(/\(.*?\)/,'')
    }.reject{|x| 
      x.split('x').length < 3
    }.uniq
    atts = {}
    dimensions_data.each do |dims|  
      dims.split('x').each do |dim| 
        @@dimensions.each do |k,v|
          atts[v] = get_f(dim) || 0 if dim.include?(k) and !atts[v]
        end 
        debugger
        0
      end
      if [atts['itemlength'], atts['itemwidth'], atts['itemheight']].uniq == [0]
        dim_array = dims.split('x')
        @@dimensions.values.each_with_index do |v, index|
          atts[v] = get_f(dim_array[index]) || 0
        end
        debugger
        0
      end
      atts.keys.each do |k|
        atts[k] = atts[k]*factor 
        atts[k] = nil if atts[k] == 0
      end
      return atts
    end
  end
  
  def vote_on_dimensions all_dimsets
    dimset_scores = {}
    all_valid_dimsets = all_dimsets.reject{|x| x.nil? or x.include?(nil) or x.include?(0) or x.length != 3}
    all_valid_dimsets.each_with_index do |set, i|
      score = 0
      other_dimsets = ([]+all_valid_dimsets)
      other_dimsets.delete_at(i)
      other_dimsets.each do |other|
        3.times do |i|
          score += 1 if other[i] == set[i]
          score += 1 if other.include?(set[i]) 
        end
        score += 2 if other.sort == set.sort
        score += 2 if other == set
      end
      dimset_scores[set] = score
    end
    #puts "All: #{all_dimsets.collect{|x| "[#{x*','}]"}*'; '}"
    #puts "Scores: #{(dimset_scores.collect{|a, b| "[#{a*','}] -- #{b}"}) * '; '}"
    best_dimset = all_valid_dimsets.sort{|a,b| dimset_scores[b] <=> dimset_scores[a]}.first
    return best_dimset
  end
  
  def dims_to_s atts
    return "" if @@dimensions.values.inject(false){|r,v| r or atts[v].nil?}
    str = @@dimensions.collect{|k,v| "#{atts[v]/100.0}\" (#{k})"}.join(' x ')
  end
end