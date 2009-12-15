module CleaningHelper
  
  def generic_model_cleaner atts
     atts['brand'] = atts['brand'].gsub(/\(.+\)/,'').strip if atts['brand']
     # Model:
     if (atts['model'].nil? or atts['model'] == atts['mpn']) and atts['title']
       # TODO combine with other model cleaner code
       dirty_model_str = atts['title'].match(/.+\s#{$model}/i).to_s.gsub(/ - /,'') 

     end
     mdls = [atts['model'], atts['mpn']].reject{|x| x.nil? or x == ''}
     mdls.each do |x|
       x.gsub!(/#{atts['brand']}\s?/i,'')
       # TODO
       (@brand_alternatives || []).each do |alts|
         if alts.include? atts['brand'].downcase
           alts.each do |altbrand|
             x.gsub!(/#{altbrand}\s?/i,'')
           end
         end
       end
       ($series || []).each do |ser|
         x.gsub!(/#{ser}\s?/i,'')
       end
       x.strip!
     end
     atts['model'] = atts['mpn'] if atts['model'].nil? or atts['model'] ==''
     return atts
  end

   # Generic cleaning code for a hash of
   # attributename => 'Attribute value [@@sep] Another att val'
   # Returns a hash with the cleaned-up values.
   def generic_cleaning_code atts, model=$model
     atts = generic_model_cleaner(atts)

     atts['title'].strip! if atts['title']

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
    # TODO what if brand not given... could we scan for all brands?
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
  
  
  # An attempt to get information from an 
  # attribute hash given that it relates to
  # printers. 
  def generic_printer_cleaning_code atts
    atts = (generic_cleaning_code atts)
    temp = atts.keys
    temp.each{|k| atts[k] = atts[k].to_s}
    
    atts.each{|x,y| atts[x] = y.split("#{@@sep}").uniq.reject{|x| x.nil?}.join("#{@@sep}") if y.type==String} 
    
    ['model', 'mpn'].each do |x|
      temp = (atts[x] || '').split(@@sep).uniq
      temp2 = []
      temp.each{|y| temp2 << clean_printer_model(y)}
      temp += temp2
      if temp.length > 0
        atts[x] = temp.sort{|a,b| likely_model_name(a) <=> likely_model_name(b)}.last
      end
    end
    
    atts['ppm'] = get_max_f(atts['ppm'])
    atts['ppmcolor'] = get_max_f(atts['ppmcolor'])
    atts['ttp'] = get_min_f(atts['ttp'])
    
    atts['paperinput'] = (atts['paperinput'] || '').scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)/).collect{|x| 
      get_max_f x}.reject{|x| x.nil?}.max
    #split(@@sep).collect{|x| get_max_f((x||'').to_s)}.reject{|x| x.nil?}.max 
   # debugger if atts['paperinput'] and atts['paperinput'] < 100
    
    # Resolution
    temp1 = (atts['resolution'] || '').scan(/\d*,?\d+\s?x\s?\d*,?\d+/i).uniq
    temp2 =  (atts['resolution'] || '').scan(/\d*,?\d+\s?(dpi|fine\s?point)/i).uniq.reject{|x| x.nil?}.collect{|x| get_f(x.to_s)}
    atts['resolutionmax'] = maxres_from_res((temp1 | temp2).join(' '))
    #  --- DIMENSIONS
    
    # TODO make this nicer
        
    (atts['dimensions'] or "").gsub!(/''/, '\"')
    (atts['dimensions'] or "").gsub!(/\(.*?\)/,'')
    
    dimensions_data = (atts['dimensions'] || "").split("#{@@sep}").reject{|x| x.nil? or x.split('x').length < 3}.uniq
    
    dimensions_data.each do |dims|  
      dims.split('x').each do |dim| 
        atts['itemlength'] = get_f(dim)*100 if dim.include? 'D' and !atts['itemlength']
        atts['itemwidth'] = get_f(dim)*100 if dim.include? 'W' and !atts['itemwidth']
        atts['itemheight'] = get_f(dim)*100 if dim.include? 'H' and !atts['itemheight']
      end
      if [atts['itemlength'], atts['itemwidth'], atts['itemheight']].uniq == [nil]
        dim_array = dims.split('x')
        atts['itemwidth'] = dim_array[0].to_f*100
        atts['itemheight'] = dim_array[1].to_f*100
        atts['itemlength'] = dim_array[2].to_f*100
      end
      atts['dimensions'] = dims and break unless [atts['itemlength'], atts['itemwidth'], atts['itemheight']].include?(nil)
    end
    
    # .. done with dimensions
    # TODO is this good?
    atts['condition'] = clean_brand atts['condition'], $conditions || atts['condition']
    atts['condition'] = clean_brand atts['title'], $conditions unless atts['condition']
    
    
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
  
end