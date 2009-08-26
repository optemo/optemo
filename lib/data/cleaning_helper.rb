module CleaningHelper
  def generic_printer_blurb_cleaner blurb
    paperinput = blurb.scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)\s(?i-mx:paper)?(?i-mx:priority)?(?i-mx:\stray)/).collect{|x| get_max_f x}.max
    return {'paperinput' => paperinput} if paperinput
  end
  
  def cartridge_cleaning_code atts
    atts = generic_cleaning_code atts
    atts.each{|x,y| atts[x]= atts[y].strip if atts[y] and atts[y].type == 'String'}
    atts['model'].gsub!(/compatible/i,'') if atts['model']
    atts['mpn'].gsub!(/compatible/i,'') if atts['mpn']
    #if atts['mpn'] and atts['model']
    #  debugger
    #  models = [atts['mpn'],atts['model']].reject{|x| x.nil? or x.strip == ''}.sort{|x,y| x.length <=> y.length}
    #  atts['model'] = models[0]
    #end
    return atts
  end
  
  def generic_cleaning_code atts, model=$model
    atts['brand'] = atts['brand'].gsub(/\(.+\)/,'').strip if atts['brand']
    # Model:
    if (atts['model'].nil? or atts['model'] == atts['mpn']) and atts['title']
      # TODO combine with other model cleaner code
      dirty_model_str = atts['title'].match(/.+\s#{$model}/i).to_s.gsub(/ - /,'') 
      
    end
    if atts['model']
      atts['model'].gsub!(/(mfp|multi-?funct?ion|duplex|faxcent(er|re)|workcent(re|er)|mono|laser|dig(ital)?|color|(black(\sand\s|\s?\/\s?)white)|network|all(\s?-?\s?)in(\s?-?\s?)one)\s?/i,'')
      atts['model'].gsub!(/printer\s?/i,'')
      atts['model'].gsub!(/#{atts['brand']}\s?/i,'')
      # TODO
      (@brand_alternatives || []).each do |alts|
        if alts.include? atts['brand'].downcase
          alts.each do |altbrand|
            atts['model'].gsub!(/#{altbrand}\s?/i,'')
          end
        end
      end
      ($series || []).each do |ser|
        atts['model'].gsub!(/#{ser}\s?/i,'')
      end
      atts['model'].strip!
    end
    
    atts['model'] = atts['mpn'] if atts['model'].nil? or atts['model'] ==''
  
    # Prices
    
    s_price_f = get_f((atts['salepricestr'] || atts['saleprice'] || '').strip.gsub(/\*/,'')) 
    l_price_f = get_f((atts['listpricestr'] || atts['listprice'] || '').strip.gsub(/\*/,'')) 
    atts['listpriceint'] = atts['listprice'] = get_price_i( l_price_f) if l_price_f
    atts['salepriceint'] = atts['saleprice'] = get_price_i( s_price_f) if s_price_f
    atts['listpricestr'] = get_price_s( l_price_f) if l_price_f
    atts['salepricestr'] = get_price_s( s_price_f) if s_price_f
    
    price_f = get_f((atts['pricestr'] || atts['price'] || atts['priceint'] || '').strip.gsub(/\*/,'')) 
    atts['priceint'] = atts['price'] = atts['salepriceint'] || atts['listpriceint'] || get_price_i(price_f)
    atts['pricestr'] = atts['salepricestr'] || atts['listpricestr'] || get_price_s(price_f)
    
    temp = (atts['imageurl'] || '').match(/(http:\/\/).*?\.(jpg|gif|jpeg|bmp)/i)
    atts['imageurl'] = temp.to_s if temp
    return atts
  
  end
  
  def generic_printer_cleaning_code atts
    
    atts = generic_cleaning_code atts
    
    atts.each{|x,y| atts[x] = y.gsub(/#{@@sep}/,'') if y.scan(/#{@@sep}/).length == 1 }
    
    atts['ppm'] = get_max_f(atts['ppm'])
    atts['ppmcolor'] = get_max_f(atts['ppmcolor'])
    atts['ttp'] = get_min_f(atts['ttp'])
    
    atts['paperinput'] = (atts['paperinput'] || '').scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)/).collect{|x| get_max_f x}.max
    #split(@@sep).collect{|x| get_max_f((x||'').to_s)}.reject{|x| x.nil?}.max 
    debugger if atts['paperinput'] and atts['paperinput'] < 100
    
    
    
    # Resolution
    atts['resolution'] = atts['resolution'].scan(/\d*,?\d+\s?x\s?\d*,?\d+/i).uniq * " #{@@sep} " if atts['resolution']
    atts['resolutionmax'] = maxres_from_res atts['resolution']
        
    # Item height, width, depth
    (atts['dimensions'] || "").split('x').each do |dim| 
      atts['itemlength'] = get_f(dim) if dim.include? 'D' and !atts['itemlength']
      atts['itemwidth'] = get_f(dim) if dim.include? 'W' and !atts['itemwidth']
      atts['itemheight'] = get_f(dim) if dim.include? 'H' and !atts['itemheight']
    end
    
    # For the OFFERING
    atts['priceint'] = get_price_i( get_f((atts['pricestr'] || '').gsub(/\*/,'')) )
    atts['pricestr'].strip! if atts['pricestr']
    
    # For the PRODUCT
    if atts['region'] == 'CA' then suffix = '_ca' else suffix='' end
    atts["listpricestr#{suffix}"].strip! if atts["listpricestr#{suffix}"]
    atts["listpriceint#{suffix}"] = get_price_i( get_f atts["listpriceint#{suffix}"] )
    
    atts['condition'] = "Refurbished" if (atts['title']||'').match(/refurbished/i) 
    atts['condition'] = "OEM" if (atts['title']||'').match(/oem/i)
    
    # Booleans
    
    atts.each{|x,y| atts[x] = nil if y=='' or (y.type==String and y.strip =='') }
    
    if(atts['colorprinter'])
      if atts['colorprinter'].match(/color/i)
        atts['colorprinter'] = true
      elsif atts['colorprinter'].match(/b(lack)?\s?(and|&|\/)?\s?w(hite)?/i)
        atts['colorprinter'] = false
      else
        debugger
        atts['colorprinter']= clean_bool(atts['colorprinter'])
      end
    end
    
    atts['printserver'] = 'true' if (atts.values.to_s).match(/(wire(d|less)|network|server)/i)
    atts['printserver'] = clean_bool(atts['printserver'])
    
    atts['scanner'] = clean_bool(atts['scanner'])
    
    atts['duplex'] = false if atts['duplex'].downcase == 'manual'
    atts['duplex'] = clean_bool(atts['duplex'])
    atts.each{|x,y| atts[x] = y.gsub(/^#{@@sep}/,'').gsub(/#{@@sep}/,' | ') if y.type==String} 
    
    return atts
  end
  
  def clean_brand title, brandlist=[]
    init_brands if $real_brands.nil?
    brandlist = $real_brands if brandlist.length ==0
    
    if title
      brandlist.each do |b|
        return b unless just_alphanumeric(title).match(/#{just_alphanumeric(b)}/i).nil?
      end
    end
    return nil
  end
  
  def clean_bool dirty_vals
    vals = []
    (dirty_vals || '').split(@@sep).each { |dirty_val| 
      val = get_b(dirty_val)
      #if val.nil? and (!dirty_val.nil? and dirty_val.strip!='')
      #  val = dirty_val.match(/(not applicable|n\/a|not available)/i).nil?
      #end
      vals << val
    }
    if vals.empty? or vals.uniq == [nil]
      return nil
    elsif vals.include? true
      return true
    else
      return false
    end
  end
end