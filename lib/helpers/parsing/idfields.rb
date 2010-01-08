module IdFieldsHelper
  
  def clean_models prodtype, dirtybrand, dirtymodels, title, brandlist=[], serieslist=[], junklist=[]
    brand = clean_brand("#{dirtybrand} #{title}", brandlist)
    models = dirtymodels.reject{|x| x.nil? or x == ''}.collect{|y| 
      models_from_title(y,brand,prodtype,junklist,serieslist)}.flatten
    models += models_from_title(title, brand, prodtype, junklist, serieslist)
    models = (most_likely_models(models)).reject{|x| likely_model_name(x) < 2}.uniq
    uniq_models = remove_duplicate_models(models, serieslist)
    return (uniq_models || []).uniq
  end
  
  def no_junk_in_title title, brand, prodtype, junklist
    # Clean junk out of title
    nojunk_title = (title || '').gsub(/\s(with|&|and|w\/)\s.*/i,'')
    list = no_blanks([prodtype, brand])
    regexlist = list.collect{|x| /(\s|^)(#{x})(\s|$)/i}
    (junklist+regexlist).each do |subme|
      nojunk_title.gsub!(subme,' ')
    end
    
    # Clean alt. brands from title
    alts = brand_alts(brand)
    alts.each do |altbrand|
      nojunk_title.gsub!(/(\s|,|^)#{altbrand}(\s|,|$)/ix,' ')
    end
    
    (nojunk_title || '').strip!
    
    return (nojunk_title || '')
  end
  
  def models_from_title title, brand, prodtype, junklist=[], series=[]
    clean_title = no_junk_in_title(title, brand, prodtype, junklist) + ' '
    temp = no_blanks(clean_title.split(/\s/))
    temp2 = []
    # Take advantage of two-part model names or really short names w/ series:
    (temp.count-1).times do |num| 
      temp2 << "#{temp[num]} #{temp[num+1]}"
    end
    possible_models = most_likely_models(temp+temp2)
    more_models = model_series_variations(possible_models, series)
    good_models = more_models.reject{|x| likely_model_name(x) < 2 }
    return good_models
  end
      
  def brand_alts brand
    return [] if brand.nil? or brand == ''
    brands = [brand]
    $brand_alternatives.each do |x|
      brands += x if x.include? brand.downcase
    end
    return brands.uniq
  end
  
  def remove_duplicate_models models, series=[]
    all = []
    models.each do |mdl|
        next if all.include?(mdl)
        match = get_same_model(mdl, all, series) 
        addme = no_blanks([match, mdl]).uniq.sort{|a,b| likely_model_name(b) <=>  likely_model_name(a) }
        next if all.include?(addme[0])
        all << addme[0] if addme[0]
    end
    return all
  end
  
  def get_same_model model, array, series=[]
    array.each{ |x| 
      return x if same_model?(x,model, series)
    }
    return nil
  end
  
  # Returns true if the strings are the same brand,
  # false otherwise
  def same_model? one, two, series=[]
    return true if one == two
    vars1 = model_series_variations(one, series).collect{|x| just_alphanumeric(x)}
    vars2 = model_series_variations(two, series).collect{|x| just_alphanumeric(x)}
    vars1.each do |var|
      vars2.each do |var2|
        if var.length > 2 and var2.length > 2
          return true if var2.match(/#{var}/)
          return true if var.match(/#{var2}/)
        else
          return true if var == var2
        end
      end
    end
    return false
  end
  
  
  # Returns true if the strings are the same brand,
  # false otherwise
  def same_brand? one, two, brandlist=[]
    cleanone = clean_brand(one,brandlist)
    cleantwo = clean_brand(two,brandlist)
    return false if cleanone.nil? or cleanone.to_s.strip == ''
    return true if cleanone == cleantwo
    return false
  end
    
  # Tries to match the brand to stuff from a list of acceptable
  # brand names. This way we're going to get more uniform values 
  # for the brand field (no unsightly capitalizations) as well as
  # avoid writing down stuff which isn't actually a brand
  def clean_brand title, brandlist=[]
    return nil if title.nil? or title.to_s.strip == ''
    ja_title = just_alphanumeric(title)

    brandlist.each do |b|
    	alts = no_blanks(brand_alts(b))
    	alts.each do |alt|
    		if alt.length < 4 # Consider whitespace
    			return b if title.match(/(\s|^)#{alt}(\s|$)/i)
    		else # Ignore whitespace
    			ja_alt = just_alphanumeric(alt)
    			if ja_alt and ja_title
    			  return b if ja_title.match(/#{ja_alt}/i)
  			  end
    		end
    	end
    end
    return nil
  end
  
  def model_series_variations models, series
    vars = []
    models.reject{|x| x.nil? or x == ''}.each{ |mn|  
        vars << mn
        series.each { |ser| 
          temp = mn.gsub(/(\s|^)#{ser}(\s|$)/i,'')
          vars << temp
        }
    }
    return vars.reject{|x| x.nil?}.collect{|x| x.strip}.uniq
  end
  
  # How likely is this to be a model name?
  def likely_model_name str
    score = 0
    return -10 if str.nil? or str.strip.length==0
  
    ja = just_alphanumeric(str)
    score += 1 if (ja.length < 18 and ja.length > 2)
    score += 2 if (ja.length < 11 and ja.length > 3)
    score += 1 if (ja.length < 9 and ja.length > 4)
    score -= 2 unless ja.match(/\d/)
    score += 1 if ja.match(/\d/) and ja.match(/\D/)
    score += 1 if (ja.match(/^\d+\D+$/) or ja.match(/^\D+\d+$/) )
    
    justnum = str.scan(/\d+/).collect{|x| (x || '').to_s.length}.sort.last || 0
    score += 2 if (justnum == 4) or (justnum > 10 and str.length == justnum)
    score += 1 if justnum == 3
    
    score += 1 if str.match(/(\s|^)i+(\s|$)/i)
    score += 2 if str.match(/ii+(\s|$)/i)
    score -= 1 if str.match(/0000/)    
    score -= 4 if str.match(/(\s|^)\d+\.\d+/)
    score -= 1 if str.match(/(\d|I)/).nil?
    #str.split(/\s/).each{|x| score -= 1 if(x.match(/[0-9]/).nil?)}
    score -= 2 if str.match(/(,|\.|:)/)
    
    score -= 2 if str.match(/(\s|^)-+(\s|$)/)
    score -= 3 if str.match(/\(|\)|\[|\]/)
    score -= 1 if str.match(/\/$/)
    
    score -= 1 if str.match(/(\s|^)for(\s|$)/)
    score -= 5 if str.match(/(\s|^)(series|and|&)(\s|$)/i)
    
    score -= 1 if str.split(/\s/).last.match(/\d/).nil?
  
    score += 10 if str == 'Verve' # TODO so hacky!
    score += 1 if str.match(/M\d.\d/) # TODO hacky
    
    $units.each do |unit|
      score -= 3 if str.match(/\d(\s|-)?#{unit}s?(\s|;|,|$)/)
      score -= 1 if str.match(/\d(\s|-)?#{unit}s?(\s|;|,|$)/i)
    end
    
    # Don't allow series...
    ([$model.name]+$brands+$series).each do |nonmodel|
      score -= 3 if str.match(/(\s|^)(#{nonmodel})(\s|,|$)/i)
    end
    # ... except if it's before a very short model name
    ($series).each do |serie|
      if str.match(/^(#{serie})\s[a-zA-Z0-9]{1,3}$/i)
        score += 2 
      end
      if str.match(/^(#{serie})\s\S{1,3}$/i)
        score += 3
      end
      if str.match(/^#{serie}\s\d\.\d$/i) 
        score += 3
      end
    end
    
    return score
  end
  
  def top_2_likely_models arr
    return (most_likely_models(arr))[0..1]
  end
  
  def most_likely_model arr
    return (most_likely_models(arr)).first
  end
  
  def most_likely_models arr
    arr_more = arr.collect{|x| [x, (x || '').match(/(\(|\[).*?(\)|\])/).to_s.gsub(/\(|\)/,'')]}.flatten.reject{|x| x.nil? or x == ''}
    return arr_more.sort{|a,b| likely_model_name(b) <=> likely_model_name(a)} || []
  end
  
end