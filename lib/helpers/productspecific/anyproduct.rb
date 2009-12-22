module CleaningHelper
   
   def product_cleaner atts
     
      ['title', 'blurb','label', 'brand', 'model', 'mpn'].each do |f|
        temp = clean_string_field(atts[f])
        atts[f] = temp
      end
     
      atts = clean_prices(atts)

      temp = (atts['imageurl'] || '').match(/(http:\/\/).*?\.(jpg|gif|jpeg|bmp)/i)
      atts['imageurl'] = temp.to_s if temp
     
      newbrand = clean_brand("#{atts['title']}}", $brands)
      newbrand ||= clean_brand("#{atts['brand']}", $brands)
      atts['brand'] = newbrand
      
      modelsb4 = no_blanks([atts['model'], atts['mpn']]).sort{|a,b| 
          likely_model_name(b) <=> likely_model_name(a)
      }
      modelsafter = no_blanks( clean_models( $model.name, ptr.brand, \
            modelsb4, ptr.title,$brands, $series, $descriptors )).uniq.reject{|x| 
                (likely_model_name(x) < 2) 
                }.sort{|a,b| 
              likely_model_name(b) <=> likely_model_name(a)
            }
      atts['model'] = modelsafter[0] || modelsb4[0]
      atts['mpn'] = modelsafter[1]
      
      atts['']
   end
   
   def clean_string_field dirty
     if dirty
       clean = dirty.to_s.strip
     end
     clean = nil if clean and clean==''
     return clean
   end
   
end