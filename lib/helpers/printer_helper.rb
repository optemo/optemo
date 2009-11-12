module PrinterHelper
  
  # A work in progress. supposed to get info
  # from a text blurb.
  def generic_printer_blurb_cleaner blurb
    paperinput = blurb.scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)\s(?i-mx:paper)?(?i-mx:priority)?(?i-mx:\stray)/).collect{|x| get_max_f x}.max
    return {'paperinput' => paperinput} if paperinput
  end

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
  
  def all_vals_to_s atts
    temp = atts.keys
    temp.each{|k| atts[k] = atts[k].to_s}
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
  
  def clean_dimensions atts, factor=100 # Assume it's in inches
    (atts['dimensions'] or "").gsub!(/''/, '\"')
    (atts['dimensions'] or "").gsub!(/\(.*?\)/,'')
    
    dimensions_data = (atts['dimensions'] || "").split("#{@@sep}").reject{|x| x.nil? or x.split('x').length < 3}.uniq
    
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
      atts['dimensions'] = dims and break unless [atts['itemlength'], atts['itemwidth'], atts['itemheight']].include?(nil)
    end
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
  
  def clean_condition atts
    atts['condition'] = clean_brand atts['condition'], $conditions || atts['condition']
    atts['condition'] = clean_brand atts['title'], $conditions unless atts['condition']
  end
  
end