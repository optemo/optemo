module CleaningHelper
  def product_cleaner atts
    # Strip all these values
    ['title', 'blurb','label', 'brand', 'model', 'mpn'].each do |f|
      atts[f] = atts[f].to_s.strip unless atts[f].nil?
    end
      
    atts['title'] = (separate(atts['title'])).first
     
    # Remove invalid image urls
    temp = (atts['imageurl'] || '').match(/(http:\/\/).*?\.(jpg|gif|jpeg|bmp)/i)
    atts['imageurl'] = temp.to_s if temp

    #First clean the brand
    newbrand = clean_brand("#{atts['title']}}", $brands)
    newbrand ||= clean_brand("#{atts['brand']}", $brands)
    atts['brand'] = newbrand

    # Then clean the model/mpn
    models_before = separate(atts['model']) + separate(atts['mpn'])
    models_before = models_before.sort{|a,b| likely_model_name(b) <=> likely_model_name(a) }.reject{|x| likely_model_name(x) < 2 }
    models_after = clean_models( $product_type, atts['brand'], models_before, atts['title'],$brands, $series, $descriptors ).uniq.compact.reject(&:blank?).reject{|x| 
      likely_model_name(x) < 2 }.sort{|a,b| 
      likely_model_name(b) <=> likely_model_name(a)
    }
    atts['model'] = models_after[0] || models_before[0]
    atts['mpn'] = models_after[1]
      
    if atts['model'] and atts['mpn'] and atts['model'].match(/#/)
      temp = atts['model']
      atts['model'] = atts['mpn']
      atts['mpn'] = temp
    end
      
    # Also clean the prices
    atts = clean_prices!(atts)
  end
end