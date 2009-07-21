module ConversionHelper
  
  @@float_rxp = /(\d+,)?\d+(\.\d+)?/
  
  require 'scraping_helper'
  include ScrapingHelper   
  
  def parse_res str
    mp = 0 # TODO
  end
  
  def self.float_rxp
    @@float_rxp
  end
  
  def to_grams wt
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
  
  def parse_time str
    return nil unless str
    day = get_f_with_units( str, /(\s)?d(ay(s)?)?/i ) || 0
    hr = get_f_with_units( str, /(\s)?h((ou)?r(s)?)?/i ) || 0
    min = get_f_with_units( str,  /(\s)?m(in(ute)?(s)?)?/i ) || 0
    sec = get_f_with_units( str,  /(\s)?s(ec(s)?)?/i ) || 0
    return [day,hr,min,sec] 
  end
  
  def get_f_with_units str, unit_regex
    return (get_f str.match(append_regex( @@float_rxp, unit_regex)).to_s) 
  end
  
  def append_regex x, y
    z = x.to_s + y.to_s
    return Regexp.new(z)
  end
end