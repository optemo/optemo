#ID FIELD CLEANING
#   clean_brand title, brandlist=[]
#   clean_model str, brand
#   same_brand? one, two
#   clean_condition str, default_real=nil
#   generic_model_cleaner atts

module IdFieldsHelper
  
  def clean_models prodtype, dirtybrand, dirtymodels, title, brandlist=[], serieslist=[], junklist=[]
    brand = clean_brand("#{dirtybrand} #{title}", brandlist)
    models = dirtymodels.reject{|x| x.nil? or x == ''}.collect{|y| 
      models_from_title(y,brand,prodtype,junklist,serieslist)}.flatten
    models += models_from_title(title, brand, prodtype, junklist, serieslist)
    models = (most_likely_models(models)).reject{|x| likely_model_name(x) < 2}
    all = []
    models.each do |mdl|
      if all.inject(true){|r,x| r and just_alphanumeric(x).match(/#{just_alphanumeric(mdl)}/ix).nil? }
        all << mdl
      end
    end
    return (all || []).uniq
  end
  
  def no_junk_in_title title, brand, prodtype, junklist
    # Clean junk out of title
    nojunk_title = title.gsub(/\s(with|&|and)\s.*/i,'')
    (junklist+[/#{prodtype}\s?/i,/#{brand}\s?/i]).each do |subme|
      nojunk_title.gsub!(subme,' ')
    end
    
    # Clean alt. brands from title
    alts = brand_alts(brand)
    alts.each do |altbrand|
      nojunk_title.gsub!(/#{altbrand}\s?/ix,'')
    end
    
    (nojunk_title || '').strip!
    
    return (nojunk_title || '')
  end
  
  def models_from_title title, brand, prodtype, junklist=[], series=[]
    clean_title = no_junk_in_title(title, brand, prodtype, junklist) + ' '
    possible_models = most_likely_models(clean_title.split(/\s/))
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
  
  # Returns true if the strings are the same brand,
  # false otherwise
  def same_brand? one, two, brandlist=[]
    brands = [just_alphanumeric(one),just_alphanumeric(two)].uniq
    return false if brands.include?('') or brands.include?(nil) or brands.length == 0
    brands.sort!
    return true if brands.length == 1
    equivalent_list = $brand_alternatives.collect{|x| 
      x.collect{|y| 
        just_alphanumeric(y)
      }.uniq
    }
    return true if equivalent_list.include?(brands)
    cleanone = clean_brand(one,brandlist)
    cleantwo = clean_brand(two,brandlist)
    return true if cleanone == cleantwo
    return false
  end
    
  # Tries to match the brand to stuff from a list of acceptable
  # brand names. This way we're going to get more uniform values 
  # for the brand field (no unsightly capitalizations) as well as
  # avoid writing down stuff which isn't actually a brand
  def clean_brand title, brandlist=[]
    return nil if title.nil? or title == ''
    brandlist.each do |b|
      alts = brand_alts(b)
      alts.each do |alt|
        return b if just_alphanumeric(title).match(/#{alt}/ix)
      end
    end
    return nil
  end
  
  def model_series_variations models, series
    vars = []
    models.reject{|x| x.nil? or x == ''}.each{ |mn|  
        vars << mn
        series.each { |ser| 
          vars << mn.gsub(/#{ser}/ix,'') if mn.match(/#{ser}/ix)
        }
    }
    return vars.reject{|x| x.nil?}.collect{|x| x.strip}
  end
  
  # How likely is this to be a model name?
  def likely_model_name str
    score = 0
    return -10 if str.nil? or str.strip.length==0
  
    ja = just_alphanumeric(str)
    score += 1 if (ja.length < 18 and ja.length > 2)
    score += 1 if (ja.length < 11 and ja.length > 4)
    score += 1 if (ja.length < 9 and ja.length > 5)
    score -= 2 unless ja.match(/\d/)
    score += 1 if ja.match(/\d/) and ja.match(/\D/)
    score += 1 if (ja.match(/^\d+\D+$/) or ja.match(/^\D+\d+$/) )
    
    justnum = str.scan(/\d+/).collect{|x| (x || '').to_s.length}.sort.last || 0
    score += 2 if (justnum == 4) or (justnum == 13 and str.length == 13)
    score += 1 if justnum == 3
    
    score -= 1 if str.match(/0000/)    
    score -= 1 if str.match(/\d\.\d/)
    score -= 1 if str.match(/\d/).nil?
    #str.split(/\s/).each{|x| score -= 1 if(x.match(/[0-9]/).nil?)}
    score -= 2 if str.match(/(,|\.)/)
    
    score -= 3 if str.match(/\(|\)/)
    score -= 1 if str.match(/\/$/)
    
    score -= 1 if str.match(/(\s|^)for(\s|$)/)
    score -= 5 if str.match(/(\s|^)(series|and|&)(\s|$)/i)
    
  
    $units.each do |unit|
      score -= 3 if str.match(/\d\s?#{unit}(s?\s|;|,)?$/)
      score -= 1 if str.match(/\d\s?#{unit}(s?\s|;|,)?$/i)
    end
    
    ([$model.name]+$brands+$series).each do |nonmodel|
      score -= 1 if str.match(/(\s|^)(#{nonmodel})(\s|$)/i)
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
    arr_more = arr.collect{|x| [x, (x || '').match(/\(.*?\)/).to_s]}.flatten.reject{|x| x.nil? or x == ''}
    return arr_more.sort{|a,b| likely_model_name(b) <=> likely_model_name(a)} || []
  end
  
end