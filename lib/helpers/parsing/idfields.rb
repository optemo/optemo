#ID FIELD CLEANING
#   clean_brand title, brandlist=[]
#   clean_model str, brand
#   same_brand? one, two
#   clean_condition str, default_real=nil
#   generic_model_cleaner atts

module IdFieldsHelper

 # TODO obsolete  
 #def brand_from_title title, brandlist=[]
 #  
 #  init_brands if $real_brands.nil?
 #  brandlist = $real_brands if brandlist.length ==0
 #  
 #  if title
 #    brandlist.each do |b|
 #      return b unless just_alphanumeric(title).match(/#{just_alphanumeric(b)}/i).nil?
 #    end
 #  end
 #  return nil
 #end
  
  def get_possible_models dirtybrand, dirtymodels, title, brandlist=[], serieslist=[]
    brand = clean_brand(dirtybrand+title)
    models = dirtymodels.reject{|x| x.nil? or x == ''}
    models += models_from_title(title)
    all = model_series_variations(models, serieslist)
    return all
  end

  def clean_model_and_mpn dirtybrand, dirtymodels, title, brandlist=[], serieslist=[]
    brand = clean_brand(dirtybrand+ ' ' + title)
    
    temp = get_possible_models(dirtybrand, dirtymodels, title, brandlist, serieslist)
    return top_2_likely_models(temp, brand)
  end
  
  def no_junk_in_title title, brand, prodtype, junklist
    # Clean junk out of title
    nojunk_title = title.gsub(/\s(with|--)\s.*/i,'')
    (junklist+[/#{prodtype}\s?/i,/#{brand}\s?/i]).each do |subme|
      nojunk_title.gsub!(subme,' ')
    end
    
    # Clean alt. brands from title
    ja_brand_alternatives = $brand_alternatives.collect{|x| x.collect{|y| just_alphanumeric(y.downcase)}}
    ja_brand_alternatives.each do |alts|
        if alts.include? just_alphanumeric(brand.downcase)
            alts.each do |altbrand|
              nojunk_title.gsub!(/#{altbrand}\s?/ix,'')
            end
        end
    end
    
    (nojunk_title || '').strip!
    
    return (nojunk_title || '')
  end
  
  def models_from_title title, brand, prodtype=$model, junklist=[]
    clean_title = no_junk_in_title(title, brand, prodtype.name, junklist) + ' '
    inbrackets = (title.match(/\(.*\)/) || '').to_s.gsub(/(\(|\))/,'')
    clean_title += no_junk_in_title(inbrackets, brand, prodtype.name, junklist) if inbrackets != ''
    possible_models = clean_title.split(/\s/)
    good_models = possible_models.reject{|x| likely_model_name(x) < 2 }
    return good_models
  end
    
  def generic_model_cleaner atts
     atts['brand'] = atts['brand'].gsub(/\(.+\)/,'').strip if atts['brand']
     # Model:
     if (atts['model'].nil? or atts['model'] == atts['mpn']) and atts['title']
       # TODO combine with other model cleaner code
       dirty_model_str = atts['title'].match(/.+\s#{$model}/i).to_s.gsub(/ - /,'') 

     end
     mdls = [atts['model'], atts['mpn']]
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
         start_index = max(start_index,index+1)
       end
       if false
         end_index = min(end_index,index-1)
       end
     end
     
     possible_models.sort{|a,b| likely_model_name(a) <=> likely_model_name(b)}
     return possible_models.uniq
  end
  
  def brand_alts brand
    return nil if brand.nil? or brand == ''
    brands = [brand]
    $brand_alternatives.each do |x|
      brands += x if x.include? brand.downcase
    end
    return brands.uniq
  end
  
  # Returns true if the strings are the same brand,
  # false otherwise
  def same_brand? one, two
    # TODO incorporate clean_brand into this method
    brands = [just_alphanumeric(one),just_alphanumeric(two)].uniq
    return false if brands.include?('') or brands.include?(nil)
    brands.sort!
    return true if brands.length == 1
    equivalent_list = $brand_alternatives.collect{|x| 
      x.collect{|y| 
        just_alphanumeric(y)
      }.uniq
    }
    return true if equivalent_list.include?(brands)
    return false
  end
    
  # Tries to match the brand to stuff from a list of acceptable
  # brand names. This way we're going to get more uniform values 
  # for the brand field (no unsightly capitalizations) as well as
  # avoid writing down stuff which isn't actually a brand
  def clean_brand title, brandlist=[]
    return nil if title.nil? or title == ''
    equivalent_list = [['hewlettpackard','hp'],['oki','okidata']]
    if title
      brandlist.each do |b|
        alts = brand_alts(b)
        alts.each do |alt|
          return b if title.match(/#{alt}/ix)
        end
      end
    end
    return nil
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
  
end