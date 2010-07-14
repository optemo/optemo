# The atthash is a mapping of attribute name to value,
# used throughout the cleaning code. It is convenient 
# because it is similar in structure to the output from
# our table scraping method.
# This module contains methods useful in manipulating 
# the atthash, but unrelated to parsing data.
module AtthashHelper
  
  @@sep = '!@!'
  
  def self.sep 
    return @@sep
  end
  
  # Merges all the values from several fields to a new field
  def multiple_fields_to_one multfields, prefix=false
      vals = []
      multfields.each do |field, anotherval|
         if anotherval and not anotherval.empty? 
           anotherval = anotherval.strip
           anotherval = field + ": #{anotherval}" if prefix
           vals << anotherval
         end 
      end
      vals.delete_if {|x| x.empty?}
      return vals * ", " unless vals.empty?
      return nil
  end
  
  def clean_sep_fields!(atts)
     atts.each do |x,y| 
       if y.class.name==String
         temp = y.split("#{@@sep}").uniq.compact.reject(&:blank?)
         atts[x] = combine_for_storage(temp)
       end
     end 
  end
  
  def separate string
    (string || '').split("#{@@sep}").compact.reject(&:blank?)
  end
  
  def combine_for_storage array
    array.reject{|x| x.nil? or x == ''}.join("#{@@sep}")
  end
  
  def combine_for_reading array
    array.reject{|x| x.nil? or x == ''}.collect{|x| x.strip}.uniq.join(", ")
  end
  
  def remove_sep! atts
    atts.each{|x,y| atts[x] = combine_for_reading(separate(y)) if y.class.name == 'String' }
  end
  
  def remove_blank_strings! atts
    atts.each { |x,y| atts[x] = nil if y and y == '' }
  end
  
  def all_vals_to_s! hash
    temp = hash.keys
    temp.each{|k| hash[k] = hash[k].to_s}
  end
  
  
  def clean_property_names atts
    clean_atts = {}.merge(atts)
    atts.each do |x,y| 
      props = get_property_names(x, $product_type)
      props.uniq.each do |property|
        clean_atts[property]= y.to_s.strip  + @@sep + "#{clean_atts[property] || ''}" if y
      end 
    end
    clean_atts
  end
  
  # Returns the first matching property or
  # nil if none found.
  def get_property_name str_dirty, model=$product_type, ignorelist=[]
    paramnames = get_property_names(str_dirty, model)
    goodparamnames = paramnames.reject{|x| ignorelist.include?(x)}
    goodparamnames.length ? goodparamnames[0] : nil # TODO get most/least specific?
  end
  
  # Returns a list of possible properties
  # that the string could mean. 
  # Example: 
  # %> get_property_names('colour ppm', Printer)
  # =>['ppm', 'colorprinter']
  def get_property_names str_dirty, model=$product_type
    str = just_alphanumeric(str_dirty)
    
    param_names= []
    # B&W:
    # black; b(lack)?\s?(\/|and|&)\s?w(hite)?; mono(chrome)? 
    
    $Continuous["all"] + $Binary["all"] + $Categorical["all"].each do |param|
      param_names << param if str.match(/#{param}/) or str.match(/#{param.gsub(/(str$|int$)/,'')}/)
    end
    
    if str.match(/price/)
      if str.match(/(orig(inal)?|reg(ular)?)/)
        param_names << 'listpricestr' 
        param_names << 'listprice'
      else
        param_names << 'saleprice'
      end
    end
    
    param_names << 'ttp' if str.match(/(firstpageoutputtime|timeto(firstpage|print))/)
    param_names << 'ppm' if str.match(/print(ing)?speed/)
    param_names << 'ppm' if str.match(/pagespermin/)    
    param_names << 'brand' if str.match(/manufacture(d|r$)/)
    param_names << 'packageweight' if str.match(/shippingweight/)
    param_names << 'mpn' if str.match(/m(fg|anufacturer)partn(o|um)/)
    param_names << 'paperinput' if str.match(/(input|sheet|paper)capacity/)
    param_names << 'paperoutput' if str.match(/outputcapacity/)
    param_names << 'resolution' if str.match(/print(ing)?quality/)    
    param_names << 'connectivity' if str.match(/printerinterface/)
    param_names << 'itemwidth' if str.match(/width/) # TODO
    param_names << 'packagewidth' if str.match(/width/) # TODO
    param_names << 'printserver' if str.match(/(network|server)/)
    param_names << 'scanner' if str.match(/scan/)
    param_names << 'colorprinter' if str.match(/(colou?r|printtechnology|printeroutput)/)
    param_names << 'imageurl' if str.match(/image|pic/)
    param_names << 'local_id' if str.match(/asin/)
    
    if str.match(/size/)
      if str.match(/media|paper|sheet|document/)
        param_names << 'papersize'
      elsif str.match(/box|package|parcel|shipping/)
        param_names << 'packagedimensions'
      else
        param_names << 'dimensions' 
      end
    end
    
    if str.match(/colou?r/)
      param_names << 'ppmcolor' if param_names.include? 'ppm'
    end
    
    if str.match(/(scan|cop(y|ie(s|r)))/i)
      param_names.delete_if{|x| x== 'resolution' or x=='ppm' or x='paperinput' or x='paperoutput'}
    end
    
    param_names << 'rating' if str.match(/average.*(review|rating)/) or str.match(/stars/)
    param_names
  end
end
