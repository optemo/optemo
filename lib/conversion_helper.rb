module ConversionHelper
  
  @@float_rxp = /(\d+,)?\d+(\.\d+)?/
  
  require 'scraping_helper'
  include ScrapingHelper   
  
  def get_inches str
    return nil unless str
    inches = get_f_with_units( str,  /\s?(in(ch(es)?)? |\")/i )
    return nil unless inches
    return inches
  end
  
  def to_mpix res
    return nil if res.nil?
    return res[2]+ res[1]/1_000 +res[0]/1_000_000
  end
  
  def parse_res str
    return nil if str.nil?
    mp = get_f_with_units( str,  /(\s)?m(ega)?\s?p(ixel(s)?)?/i ) || 0
    mp = get_f_with_units( str,  /(\s)?k(ilo)?\s?p(ixel(s)?)?/i ) || 0
    p = get_f_with_units( str,  /(\s)b(yte(s)?)?/i ) || 0
    return [mp, kp, p] 
  end
  
  # Returns [WIDTH, DEPTH, HEIGHT]
  def parse_dimensions str
    return nil if (str.nil? or str=='')
    dims = [nil,nil,nil]
    str.split('x').each do |dim| 
      dims[0] = get_f(dim) if (dim.match(/w/i) and get_f(dim) != 0)
      dims[1] = get_f(dim) if (dim.match(/[dl]/i) and get_f(dim) != 0)
      dims[2] = get_f(dim) if (dim.match(/h/i)  and get_f(dim) != 0)
    end
    return dims unless dims.uniq == [nil]
    return nil
  end
  
  def self.float_rxp
    @@float_rxp
  end
  
  def to_grams wt
    return nil if wt.nil? or wt.length ==2
    return (wt[0]*1000+wt[1]+wt[2]/1000)
  end
  
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
  
  def to_sec time
    return time[3] + 60*(time[2]+ 60*( time[1] + 24*time[0])  )
  end
  
  def to_days time
    return time[3]+ 7*(time[2]+ 30*( time[1] + 365*time[0])  )
  end
  
  def parse_time str
    return nil unless str
    day = get_f_with_units( str, /(\s)?d(ay(s)?)?/i ) || 0
    hr = get_f_with_units( str, /(\s)?h((ou)?r(s)?)?/i ) || 0
    min = get_f_with_units( str,  /(\s)?m(in(ute)?(s)?)?/i ) || 0
    sec = get_f_with_units( str,  /(\s)?s(ec(s)?)?/i ) || 0
   # return [yr,mo,wk,day,hr,min,sec] 
   return [day,hr,min,sec]
  end
  
  def parse_long_time str
    yr = get_f_with_units( str, /(\s)?y((ea)?r(s)?)?/i ) || 0
    month = get_f_with_units( str, /(\s)?m(o(nth)?(s)?)?/i ) || 0
    wk = get_f_with_units( str, /(\s)?w((ee)?k(s)?)?/i ) || 0
    short = parse_time str
    return [yr,month,wk,short].flatten
  end
  
  def get_f_with_units str, unit_regex
    return (get_f str.match(append_regex( @@float_rxp, unit_regex)).to_s) 
  end
  
  def append_regex x, y
    z = x.to_s + y.to_s
    return Regexp.new(z)
  end
end