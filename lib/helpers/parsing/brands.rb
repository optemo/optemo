module BrandsHelper
  
  def model_cleaner atts, brandlist
     possible_models = [atts['model'], atts['mpn']]
    
     atts['brand'] = atts['brand'].gsub(/\(.+\)/,'').strip if atts['brand']
     
     brand = clean_brand(atts['brand'], brandlist)
     
     title = atts['title']
     title_words = title.split(/\s/).reject{|x| x.nil? or x.length == 0}
     start_index = 0
     end_index =  title_words.length
     title_words.each_with_index do |word,index|
       if same_brand?(brand, word) or same_brand(atts['brand'],word) #or @@series.include?(word)
         start_index = max(start_index,index)
       end
       if false
         end_index = min(end_index,index)
       end
     end
     
     possible_models.sort{|a,b| likely_model_name(a) <=> likely_model_name(b)}
     return possible_models.uniq
  end

  def model_series_variations models, series
    vars = []
    models.each{ |mn|  
        vars << mn
        vars << mn.gsub(/\#.*$/, '')
        series.each { |ser| 
          vars << mn.gsub(/#{ser}/ix,'') if mn.match(/#{ser}/ix)
        }
    }
    return vars.reject{|x| x.nil?}.collect{|x| x.strip}.reject{|x| x == ''}.uniq
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
    
  def remove_sep atts
    atts.each{|x,y| atts[x] = y.split("#{@@sep}").reject{|x| x.nil?}.collect{|x| x.strip}.uniq.join(' | ') if y.type==String} 
  end
  
  # Tries to match the brand to stuff from a list of acceptable
  # brand names. This way we're going to get more uniform values 
  # for the brand field (no unsightly capitalizations) as well as
  # avoid writing down stuff which isn't actually a brand
  def clean_brand dirtybrand, brandlist
    brandlist.each do |b|
      return b if same_brand?(dirtybrand, b)
      return b if dirtybrand.match(/#{b}/ix) or b.match(/#{dirtybrand}/ix)
    end
    return nil
  end
  
  def top_2_likely_models arr, brand=''
    return (most_likely_models(arr,brand))[0..1]
  end
  
  def most_likely_model arr, brand=''
    return (most_likely_models(arr,brand)).first
  end
  
  def most_likely_models arr, brand=''
    arr_more = arr.collect{|x| [x, (x || '').match(/\(.*?\)/).to_s]}.flatten.reject{|x| x.nil? or x == ''}
    return arr_more.sort{|a,b| likely_model_name(b) <=> likely_model_name(a)}
  end
  
  # Returns true if the strings are the same brand,
  # false otherwise
  def same_brand? one, two
    brands = [just_alphanumeric(one),just_alphanumeric(two)].uniq
    return false if brands.include?('') or brands.include?(nil)
    brands.sort!
    return true if brands.length == 1
    equivalent_list = [['hewlettpackard','hp'],['oki','okidata']]
    return true if equivalent_list.include?(brands)
    return false
  end
    
  # How likely is this to be a model name?
  def likely_model_name str
    score = 0
    return -10 if str.nil? or str.strip.length==0
  
    ja = just_alphanumeric(str)
    score += 1 if (ja.length < 17 and ja.length > 3)
    score += 1 if (ja.length < 11 and ja.length > 4)
    score += 1 if (ja.length < 9 and ja.length > 5)
    
    score -= 2 if str.match(/[0-9]/).nil?
    str.split(/\s/).each{|x| score -= 1 if(x.match(/[0-9]/).nil?)}
    score -= 2 if str.match(/,|\./)
    score -= 1 if str.match(/for/)
    score -= 3 if str.match(/\(|\)/)
    score -= 5 if str.match(/(series|and|&)\s/i)
  
    return score
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
  
  def most_likely_model arr, brand=''
    arr_more = arr.collect{|x| [x, (x || '').match(/\(.*?\)/).to_s]}.flatten.reject{|x| x.nil? or x == ''}
    return arr_more.sort{|a,b| likely_model_name(a) <=> likely_model_name(b)}.last
  end
  
  def model_series_variations models, series
    vars = []
    models.each{ |mn|  
        vars << mn
        series.each { |ser| 
          vars << mn.gsub(/#{ser}/ix,'') if mn.match(/#{ser}/ix)
        }
    }
    return vars.reject{|x| x.nil?}.collect{|x| x.strip}
  end
  
  # Returns true if the strings are the same brand,
  # false otherwise
  def same_brand? one, two
    brands = [just_alphanumeric(one),just_alphanumeric(two)].uniq
    return false if brands.include?('') or brands.include?(nil)
    brands.sort!
    return true if brands.length == 1
    equivalent_list = [['hewlettpackard','hp'],['oki','okidata']]
    return true if equivalent_list.include?(brands)
    return false
  end
    
  # How likely is this to be a model name?
  def likely_model_name str
    score = 0
    return -10 if str.nil? or str.strip.length==0
  
    ja = just_alphanumeric(str)
    score += 1 if (ja.length < 17 and ja.length > 3)
    score += 1 if (ja.length < 11 and ja.length > 4)
    score += 1 if (ja.length < 9 and ja.length > 5)
    
    score -= 2 if str.match(/[0-9]/).nil?
    str.split(/\s/).each{|x| score -= 1 if(x.match(/[0-9]/).nil?)}
    score -= 2 if str.match(/,|\./)
    score -= 1 if str.match(/for/)
    score -= 3 if str.match(/\(|\)/)
    score -= 5 if str.match(/(series|and|&)\s/i)
  
    return score
  end
end