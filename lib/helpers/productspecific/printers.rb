#PRINTER PARSING (Printing resolution, ppm, tray size...)
#   parse_max_num_pages str
#   get_ppm str


#RANDOM PRINTER STUFF
#   generic_printer_cleaning_code atts
#   clean_printer_model dirtymodel, brand=''
#   generic_printer_blurb_cleaner blurb
#   get_best_printer_model atts
#   clean_ppm atts
#   clean_printer_booleans atts
#   clean_printer_resolution atts
#   clean_paperinput_with_units atts
#   (deprecate?) clean_printer_model dirtymodel, brand=''
#

module PrinterHelper
  
  def clean_title str
    str.strip!
  end
  
  def clean_warranty atts
     atts = clean_prices(atts)
  
     if atts['parts'] or atts['labor']
       temp =  many_fields_to_one(['parts', 'labor'], atts, true)  
       atts['warranty'] = (atts['warranty'] || '') + " #{temp}"
     end  
  
     temp = (atts['imageurl'] || '').match(/(http:\/\/).*?\.(jpg|gif|jpeg|bmp)/i)
     atts['imageurl'] = temp.to_s if temp
     return atts
   end
  
  def clean_printer_model dirtymodel, brand=''
    return nil if dirtymodel == nil
    clean_model_str = dirtymodel.gsub(/(mfp|multi-?funct?ion|duplex|faxcent(er|re)|workcent(re|er)|mono|laser|dig(ital)?|color|(black(\sand\s|\s?\/\s?)white)|network|all(\s?-?\s?)in(\s?-?\s?)one)\s?/i,'')
    clean_model_str.gsub!(/(ink|chrome|tabloid|aio\sint|\(|,|\d+\s?x\s?\d+\s?(dpi)?|fast\sethernet|led).*/i,'')
    clean_model_str.gsub!(/printer\s?/i,'')
    clean_model_str.gsub!(/#{brand}\s?/i,'')
    ja_brand_alternatives = $brand_alternatives.collect{|x| x.collect{|y| just_alphanumeric(y.downcase)}}
    ja_brand_alternatives.each do |alts|
        if alts.include? just_alphanumeric(brand.downcase)
            alts.each do |altbrand|
              clean_model_str.gsub!(/#{altbrand}\s?/ix,'')
            end
        end
    end
    clean_model_str.strip!
    return clean_model_str
  end
  
  def clean_separators atts
    atts.each{|x,y| atts[x] = y.split("#{@@sep}").uniq.reject{|x| x.nil?}.join("#{@@sep}") if y.type==String} 
  end
  
  def get_best_printer_model atts
    ['model', 'mpn'].each do |x|
      temp = (atts[x] || '').split(@@sep).uniq
      temp2 = []
      temp.each{|y| temp2 << clean_printer_model(y)}
      temp += temp2
      if temp.length > 0
        atts[x] = temp.sort{|a,b| likely_model_name(a) <=> likely_model_name(b)}.last
      end
    end
  end
  
  def clean_ppm atts
    atts['ppm'] = get_max_f(atts['ppm'])
    atts['ppmcolor'] = get_max_f(atts['ppmcolor'])
  end
  
  def remove_blank_strings atts
    atts.each{|x,y| atts[x] = nil if y=='' or (y.type==String and y.strip =='') }
  end
  
  
  def clean_printer_booleans atts
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
  end
  
  def clean_printer_resolution atts
    temp1 = (atts['resolution'] || '').scan(/\d*,?\d+\s?x\s?\d*,?\d+/i).uniq
    temp2 =  (atts['resolution'] || '').scan(/\d*,?\d+\s?(dpi|fine\s?point)/i).uniq.reject{|x| x.nil?}.collect{|x| get_f(x.to_s)}
    atts['resolutionmax'] = maxres_from_res((temp1 | temp2).join(' '))
  end
  
  def clean_paperinput_with_units atts
    atts['paperinput'] = (atts['paperinput'] || '').scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)/).collect{|x| 
    get_max_f x}.reject{|x| x.nil?}.max
  end
  
  def clean_condition title, condition, condition_list=$conditions
    clean = clean_enum(condition, condition_list) || condition
    clean = clean_enum(title, condition_list) unless clean
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