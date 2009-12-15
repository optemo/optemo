
module DimensionsHelper
  #LENGTHS/WEIGHTS
  #   to_cm length
  #   parse_metric_length str
  #   parse_metric_dimensions str
  #   to_grams wt
  #   parse_weight str
  
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
  
  # Converts metric weight array([kg,g,mg]) to grams
  def to_grams wt
    return nil if wt.nil? or wt.length ==2
    return (wt[0]*1000+wt[1]+wt[2]/1000)
  end
  
  def clean_dims dimensions, factor=100
    str =(dimensions or "").gsub(/''/, '\"').gsub(/\(.*?\)/,'')
    dimensions_data = separate(str).reject{|x| x.split('x').length < 3}.uniq
    atts = {}
    dimensions_data.each do |dims|  
      dims.split('x').each do |dim| 
        atts['itemlength'] = get_f(dim)*factor if dim.include? 'D' and !atts['itemlength']
        atts['itemwidth'] =  get_f(dim)*factor if dim.include? 'W' and !atts['itemwidth']
        atts['itemheight'] = get_f(dim)*factor if dim.include? 'H' and !atts['itemheight']
      end
      if [atts['itemlength'], atts['itemwidth'], atts['itemheight']].uniq == [nil]
        dim_array = dims.split('x')
        atts['itemwidth'] =  dim_array[0].to_f*factor
        atts['itemheight'] = dim_array[1].to_f*factor
        atts['itemlength'] = dim_array[2].to_f*factor
      end
      return atts
  end
end