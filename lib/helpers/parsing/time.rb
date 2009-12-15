module TimeParser
  
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

end