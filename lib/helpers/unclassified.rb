module CleaningHelper
  
   # Generic cleaning code for a hash of
   # attributename => 'Attribute value [@@sep] Another att val'
   # Returns a hash with the cleaned-up values.
   def generic_cleaning_code atts, model=$model
     atts = generic_model_cleaner(atts)

     atts['title'].strip! if atts['title']

     atts = clean_prices(atts)

     temp = (atts['imageurl'] || '').match(/(http:\/\/).*?\.(jpg|gif|jpeg|bmp)/i)
     atts['imageurl'] = temp.to_s if temp
     return atts
   end
  
end