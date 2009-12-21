module PrinterHelper  
  
  # An attempt to get information from an 
  # attribute hash given that it relates to
  # printers. 
  def generic_printer_cleaning_code atts
    atts = (generic_cleaning_code atts)
    temp = atts.keys
    temp.each{|k| atts[k] = atts[k].to_s}
    
    atts.each{|x,y| atts[x] = y.split("#{@@sep}").uniq.reject{|x| x.nil?}.join("#{@@sep}") if y.type==String} 
    
    ['ppm', 'ppmcolor'].each do |maxfield|
      temp = get_max_f(atts[maxfield])
      atts[maxfield] = temp
    end
    atts['ppm'] = [atts['ppm'], atts['ppmcolor']].max
    
    ['ttp'].each do |minfield|
      temp = get_min_f(atts[minfield])
      atts[minfield] = temp
    end
    
    # Dimensions
    temp = atts['dimensions']    
    
    
        
    atts['paperinput'] = (atts['paperinput'] || '').scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)/).collect{|x| 
      get_max_f x}.reject{|x| x.nil?}.max
    
    # Resolution
    temp1 = (atts['resolution'] || '').scan(/\d*,?\d+\s?x\s?\d*,?\d+/i).uniq
    temp2 =  (atts['resolution'] || '').scan(/\d*,?\d+\s?(dpi|fine\s?point)/i).uniq.reject{|x| x.nil?}.collect{|x| get_f(x.to_s)}
    atts['resolutionmax'] = maxres_from_res((temp1 | temp2).join(' '))
    
    atts['condition'] = clean_condition( atts['condition'], $conditions )
            
    # Booleans
    
    atts.each{|x,y| atts[x] = nil if y=='' or (y.type==String and y.strip =='') }
    
    if(atts['colorprinter'])
      if atts['colorprinter'].match(/color/i)
        atts['colorprinter'] = true
      elsif atts['colorprinter'].match(/b(lack)?\s?(and|&|\/)?\s?w(hite)?/i)
        atts['colorprinter'] = false
      else
        atts['colorprinter']= clean_bool(atts['colorprinter'])
      end
    end
    
    atts['printserver'] = 'true' if (atts.values.to_s).match(/(wire(d|less)|network|server)/i)
    atts['printserver'] = clean_bool(atts['printserver'])
    
    atts['scanner'] = clean_bool(atts['scanner'])
    
    atts['duplex'] = false if (atts['duplex'] || '').downcase == 'manual'
    atts['duplex'] = clean_bool(atts['duplex'])
    remove_sep atts
    return atts
  end
  
  
  def clean_warranty atts
     atts = clean_prices(atts)
  
     if atts['parts'] or atts['labor']
       atts['warranty'] =  multiple_fields_to_one([atts['parts'], atts['labor']], true)
       atts['warranty'] = (atts['warranty'] || '') + " #{temp}"
     end  
  
     temp = (atts['imageurl'] || '').match(/(http:\/\/).*?\.(jpg|gif|jpeg|bmp)/i)
     atts['imageurl'] = temp.to_s if temp
     return atts
   end
  
  
  def clean_printer_resolution atts
    temp1 = (atts['resolution'] || '').scan(/\d*,?\d+\s?x\s?\d*,?\d+/i).uniq
    temp2 =  (atts['resolution'] || '').scan(/\d*,?\d+\s?(dpi|fine\s?point)/i).uniq.reject{|x| x.nil?}.collect{|x| get_f(x.to_s)}
    atts['resolutionmax'] = maxres_from_res((temp1 | temp2).join(' '))
  end
  
  def clean_paperinput_with_units paperinput_dirty
    returnme = (paperinput_dirty || '').scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)/).collect{|x| 
    get_max_f x}.reject{|x| x.nil?}.max
    return returnme
  end
  
  def clean_condition title, condition, condition_list=$conditions
    clean = clean_enum(condition, condition_list)
    clean ||= clean_enum(title, condition_list)
    clean ||= condition 
    return clean
  end
  
  def get_ppm str
    ppm = get_f_with_units(str, /-?p(ages|rints)?\s?p(er)?\s?m(in)?(ute)?/i)
    return ppm
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
  
end