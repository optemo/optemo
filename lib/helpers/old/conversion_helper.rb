module ConversionHelper
  
  @@float_rxp = /(\d+,)?\d+(\.\d+)?/
  
  def self.float_rxp
    return @@float_rxp
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
  
  # Gets maximum resolution from resolution
  def maxres_from_res res
    return nil if res.nil?
    maxres = get_max_f(res)
    return maxres
  end
  
  # Gets the max. numerical value from something in
  # units of pages or sheets.  Returns an integer.
  def parse_max_num_pages str
    return nil if str.nil?
    numpages = get_f_with_units( (str || '').gsub(/\+\s?\d+/,''),  /-?(sheet|page)(s)?/i )
    return numpages.to_i if numpages
    return nil
  end
  
  
  # Gets the max. numerical value from something in
  # units of pages or sheets.  Returns an integer.
  def parse_dpi str
    return nil if str.nil?
    res = str.match(/\d+\s?(dpi)?(\s?x\s?\d+)\s?dpi/)
    return res.to_s if res
    return nil
  end
  
  
  # Gets the zoom of a lens given a string describing
  # the lens and containing the lens' focal lengths.
  def parse_lens str
    return nil if str.nil?
    lens_substr = str.scan(/with.*?\d+?.*?\d+?.*?lens/i).to_s #  || str
    return nil if lens_substr.nil?
    lens_params = lens_substr.match(/\d+(mm)?\s?-?\s?\d+(mm)?/).to_s
    return nil if lens_substr.nil? or lens_substr.strip == ""
    zoom = focal_lengths_to_zoom(lens_params)
    return zoom
  end
  
  # Given just the string that describes focal lengths of a single
  # lens it gets the zoom (max focal length / min focal length)
  def focal_lengths_to_zoom str
    min_focal_length = get_min_f(str)
    max_focal_length = get_max_f(str)
    zoom = (max_focal_length / min_focal_length) if min_focal_length and max_focal_length
    #debugger if zoom <= 1
    return zoom || nil
  end
  
  # Gets optical zoom from a string if there is a number in there for it.
  def parse_ozoom str
    return nil if str.nil?
    ozoom =  get_f( str.match( append_regex(@@float_rxp, /\s?x (optical )?zoom/i)).to_s )
    return ozoom if ozoom and ozoom >= 1
    return nil 
  end
  
  # Gets a number associated with units of inches from a string.
  def get_inches str
    return nil unless str
    inches = get_f_with_units( str,  /(\s|-)?(in(ch(es)?)? |\")/i )
    return nil unless (inches and inches > 0)
    return inches
  end
  
  # Converts resolution(array: [megapixels, kilopixels, pixels]) to megapixels
  def to_mpix res
    return nil if res.nil?
    mpix = res[0]+ res[1]/1_000 +res[2]/1_000_000
    return mpix unless mpix == 0
    return nil
  end
  
  # Gets resolution(array: [megapixels, kilopixels, pixels]) from a string
  def parse_res str
    return nil if str.nil?
    mp = get_f_with_units( str,  /(\s)?m(ega)?\s?p(ixel(s)?)?/i ) || 0
    kp = get_f_with_units( str,  /(\s)?k(ilo)?\s?p(ixel(s)?)?/i ) || 0
    p = get_f_with_units( str,  /(\s)?p(ixel(s)?)?/i ) || 0
    return [mp, kp, p] 
  end
  
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
  
  # Returns a regex for the most general number possible: a float
  # which might have commas as thousands-separators
  def self.float_rxp
    @@float_rxp
  end
  
  # Converts metric weight array([kg,g,mg]) to grams
  def to_grams wt
    return nil if wt.nil? or wt.length ==2
    return (wt[0]*1000+wt[1]+wt[2]/1000)
  end
  
  def get_ppm str
    ppm = get_f_with_units(str, /-?p(ages|rints)?\s?p(er)?\s?m(in)?(ute)?/i)
    return ppm
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
  
  # Converts short time array([day,hr,min,sec]) to seconds
  def to_sec time
    return time[3] + 60*(time[2]+ 60*( time[1] + 24*time[0])  )
  end
  
  # Converts long time array( [yr,mo,wk,day,hr,min,sec] ) to days
  def to_days time
    return time[3]+ 7*(time[2]+ 30*( time[1] + 365*time[0])  )
  end
  
  # Gets time ( array: [day,hr,min,sec] ) from a string
  def parse_time str
    return nil unless str
    day = get_f_with_units( str, /(\s)?d(ay(s)?)?/i ) || 0
    hr = get_f_with_units( str, /(\s)?h((ou)?r(s)?)?/i ) || 0
    min = get_f_with_units( str,  /(\s)?m(in(ute)?(s)?)?/i ) || 0
    sec = get_f_with_units( str,  /(\s)?s(ec(s)?)?/i ) || 0
  
   return [day,hr,min,sec]
  end
  
  # Gets time ( array: [yr,mo,wk,day,hr,min,sec] ) from a string
  def parse_long_time str
    yr = get_f_with_units( str, /(\s)?y((ea)?r(s)?)?/i ) || 0
    month = get_f_with_units( str, /(\s)?m(o(nth)?(s)?)?/i ) || 0
    wk = get_f_with_units( str, /(\s)?w((ee)?k(s)?)?/i ) || 0
    short = parse_time str
    return [yr,month,wk,short].flatten
  end
  
  # Gets a float with given units from a string
  def get_f_with_units str, unit_regex
    return (get_f str.match(float_and_regex(unit_regex)).to_s) 
  end
  
  # Gets a float with given units from a string
  def get_f_with_units_in_front str, unit_regex
    return (get_f str.match(append_regex( unit_regex, @@float_rxp)).to_s) 
  end
  
  # Adds on a regular expression to the regex for a float.
  def float_and_regex x
    return append_regex @@float_rxp, x
  end
  
  # Glues two regexes together side by side
  def append_regex x, y
    z = x.to_s + y.to_s
    return Regexp.new(z)
  end
end