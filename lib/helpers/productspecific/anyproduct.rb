module CleaningHelper
   
   def product_cleaner atts
      # Strip all these values
      ['title', 'blurb','label', 'brand', 'model', 'mpn'].each do |f|
        temp = clean_string_field(atts[f])
        atts[f] = temp
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
      debugger
      modelsb4 = separate(atts['model']) + separate(atts['mpn'])
      debugger
      modelsb4 = modelsb4.sort{|a,b| likely_model_name(b) <=> likely_model_name(a) }.reject{|x| likely_model_name(x) < 2 }
      modelsafter = no_blanks( clean_models( $model.name, atts['brand'], \
            modelsb4, atts['title'],$brands, $series, $descriptors )).uniq.reject{|x| 
              likely_model_name(x) < 2 }.sort{|a,b| 
              likely_model_name(b) <=> likely_model_name(a)
      }
      debugger
      atts['model'] = modelsafter[0] || modelsb4[0]
      atts['mpn'] = modelsafter[1]
      
      # Also clean the prices
      atts = clean_prices!(atts)
   end
   
   def clean_string_field dirty
     if dirty
       clean = dirty.to_s.strip
     end
     clean = nil if clean and clean==''
     return clean
   end
   
end