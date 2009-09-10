module CleaningHelper
  
  # This thing is used to separate values when they were
  # both retrieved as possible values for a given attribute,
  # so as not to use commas which are more commonplace.
  @@sep = '!@!'
  def self.sep
    return @@sep
  end
  
  # A work in progress. supposed to get info
  # from a text blurb.
  def generic_printer_blurb_cleaner blurb
    paperinput = blurb.scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)\s(?i-mx:paper)?(?i-mx:priority)?(?i-mx:\stray)/).collect{|x| get_max_f x}.max
    return {'paperinput' => paperinput} if paperinput
  end
  
  # Generic cleaning code for a hash of
  # attributename => 'Attribute value [@@sep] Another att val'
  # Returns a hash with the cleaned-up values.
  def generic_cleaning_code atts, model=$model
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
    atts['title'].strip! if atts['title']
  
    atts = clean_prices(atts)
    
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
              clean_model_str.gsub!(/#{altbrand}\s?/i,'')
            end
        end
    end
    clean_model_str.strip!
    return clean_model_str
  end
  
  def clean_property_names atts
    clean_atts = {}.merge(atts)
    atts.each do |x,y| 
      props = get_property_names(x, $model)
      props.uniq.each do |property|
        clean_atts[property]= y.to_s.strip  + @@sep + "#{clean_atts[property] || ''}" if y
      end 
    end
    return clean_atts
  end
  
  # An attempt to get information from an 
  # attribute hash given that it relates to
  # printers. 
  def generic_printer_cleaning_code atts
    
    atts = (generic_cleaning_code atts)
    temp = atts.keys
    temp.each{|k| atts[k] = atts[k].to_s}
    
    atts.each{|x,y| atts[x] = y.gsub(/#{@@sep}/,'') if y.scan(/#{@@sep}/).length == 1 }
    
    atts['model'] = clean_printer_model(atts['model'], atts['brand'])
    atts['mpn'] = clean_printer_model(atts['mpn'], atts['brand'])
    
    atts['ppm'] = get_max_f(atts['ppm'])
    atts['ppmcolor'] = get_max_f(atts['ppmcolor'])
    atts['ttp'] = get_min_f(atts['ttp'])
    
    atts['paperinput'] = (atts['paperinput'] || '').scan(/(?-mix:\d*,?\d+\s?-?)(?i-mx:sheets?)|(?i-mx:pages?)/).collect{|x| 
      get_max_f x}.reject{|x| x.nil?}.max
    #split(@@sep).collect{|x| get_max_f((x||'').to_s)}.reject{|x| x.nil?}.max 
    debugger if atts['paperinput'] and atts['paperinput'] < 100
    
    # Resolution
    atts['resolution'] = atts['resolution'].scan(/\d*,?\d+\s?x\s?\d*,?\d+/i).uniq * " #{@@sep} " if atts['resolution']
    atts['resolutionmax'] = maxres_from_res atts['resolution']
    
    #  --- DIMENSIONS
    
    # TODO make this nicer
        
    (atts['dimensions'] or "").gsub!(/''/, '\"')
    (atts['dimensions'] or "").gsub!(/\(.*?\)/,'')
      
    (atts['dimensions'] || "").split('x').each do |dim| 
      atts['itemlength'] = get_f(dim)*100 if dim.include? 'D' and !atts['itemlength']
      atts['itemwidth'] = get_f(dim)*100 if dim.include? 'W' and !atts['itemwidth']
      atts['itemheight'] = get_f(dim)*100 if dim.include? 'H' and !atts['itemheight']
    end
    
    if atts['dimensions'] and [atts['itemlength'], atts['itemwidth'], atts['itemheight']].uniq == [nil]
      dims = atts['dimensions'].split('x')
      break if dims.length < 3
      # TODO item lwh not what I thought?
      atts['itemlength'] = dims[2].to_f*100
      atts['itemwidth'] = dims[0].to_f*100
      atts['itemheight'] = dims[1].to_f*100
    end
    
    # .. done with dimensions
    
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
        atts['colorprinter']= clean_bool(atts['colorprinter'])
      end
    end
    
    atts['printserver'] = 'true' if (atts.values.to_s).match(/(wire(d|less)|network|server)/i)
    atts['printserver'] = clean_bool(atts['printserver'])
    
    atts['scanner'] = clean_bool(atts['scanner'])
    
    atts['duplex'] = false if (atts['duplex'] || '').downcase == 'manual'
    atts['duplex'] = clean_bool(atts['duplex'])
    atts.each{|x,y| atts[x] = y.gsub(/^#{@@sep}/,'').gsub(/#{@@sep}/,' | ') if y.type==String} 
    
    return atts
  end
  
  # If any of the 'indicator properties' in the 
  # attribute hash are not nil, the boolean property
  # is set to true in the attribute hash. Otherwise 
  # it's set to the default (or not set if default=nil).
  # Returns the attribute hash.
  def infer_boolean bool_property, indicator_properties, atts, default=nil
    atts[bool_property] = default unless (atts[bool_property] or default.nil?)
    indicator_properties.each do |x|
      atts[bool_property] = true unless atts[x].nil?
    end
    return atts
  end
  
  # Figures out all the price attributes
  def clean_prices atts
    s_price_f = get_f((atts['salepricestr'] || atts['saleprice'] || '').strip.gsub(/\*/,'')) 
    l_price_f = get_f((atts['listpricestr'] || atts['listprice'] || '').strip.gsub(/\*/,'')) 
    atts['listpriceint'] = atts['listprice'] = get_price_i( l_price_f) if l_price_f
    atts['salepriceint'] = atts['saleprice'] = get_price_i( s_price_f) if s_price_f
    atts['listpricestr'] = get_price_s( l_price_f) if l_price_f
    atts['salepricestr'] = get_price_s( s_price_f) if s_price_f
    
    price_f = get_f((atts['pricestr'] || atts['price'] || atts['priceint'] || '').strip.gsub(/\*/,'')) 
    atts['priceint'] = atts['price'] = atts['salepriceint'] || atts['listpriceint'] || get_price_i(price_f)
    atts['pricestr'] = atts['salepricestr'] || atts['listpricestr'] || get_price_s(price_f)
    
    return atts
  end
  
  # Tries to match the brand to stuff from a list of acceptable
  # brand names. This way we're going to get more uniform values 
  # for the brand field (no unsightly capitalizations) as well as
  # avoid writing down stuff which isn't actually a brand
  def clean_brand title, brandlist=[]
    brandlist = $real_brands if brandlist.length ==0
    
    if title
      brandlist.each do |b|
        return b unless just_alphanumeric(title).match(/#{just_alphanumeric(b)}/i).nil?
      end
    end
    return nil
  end
  
  # Cleans a list of Boolean values to be either true or false 
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