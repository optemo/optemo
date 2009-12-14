module Database
  # Returns the first matching property or
  # nil if none found.
  def get_property_name str_dirty, model=$model, ignorelist=[]
    paramnames = get_property_names(str_dirty, model)
    goodparamnames = paramnames.reject{|x| ignorelist.include?(x)}
    return nil if goodparamnames.length == 0
    return goodparamnames[0] # TODO get most/least specific?
  end
  
  # Returns a list of possible properties
  # that the string could mean. 
  # Example: 
  # %> get_property_names('colour ppm', Printer)
  # =>['ppm', 'colorprinter']
  def get_property_names str_dirty, model=$model
    str = just_alphanumeric(str_dirty)
    
    param_names= []
    # B&W:
    # black; b(lack)?\s?(\/|and|&)\s?w(hite)?; mono(chrome)? 
    
    model.column_names.each do |param|
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
     
    return param_names
  end
    
  
end