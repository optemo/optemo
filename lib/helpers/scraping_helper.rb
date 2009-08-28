module ScrapingHelper
  
  @@float_rxp = /(\d+,)?\d+(\.\d+)?/
  
  def get_property_name str_dirty, model=$model
    paramnames = get_property_names str_dirty, model
    return nil if paramnames.length == 0
    return paramnames[0] # TODO get most/least specific?
  end
  
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
    param_names << 'papersize' if str.match(/mediasize/)
    param_names << 'connectivity' if str.match(/printerinterface/)
    param_names << 'itemwidth' if str.match(/width/) # TODO
    param_names << 'packagewidth' if str.match(/width/) # TODO
    param_names << 'printserver' if str.match(/(network|server)/)
    param_names << 'scanner' if str.match(/scan/)
    param_names << 'colorprinter' if str.match(/(colou?r|printtechnology|printeroutput)/)
    param_names << 'dimensions' if str.match(/size/)
    param_names << 'imageurl' if str.match(/image|pic/)
    
    if str.match(/colou?r/)
      param_names << 'ppmcolor' if param_names.include? 'ppm'
    end
    
    if str.match(/(scan|cop(y|ie(s|r)))/i)
      param_names.delete_if{|x| x== 'resolution' or x=='ppm' or x='paperinput' or x='paperoutput'}
    end
    
    param_names << 'dimensions' if str.match(/dimensions/)
    
    param_names << 'rating' if str.match(/average.*(review|rating)/) or str.match(/stars/)
     
    return param_names
  end
    
  # Returns a hash of (name, value) from a table where
  # each row has a name cell and a value cell.
  # Pass the table as Nokogiri element 
  # and the name & value elements' css selectors.
  def scrape_table table, name_css, val_css
    spec_hash = {}
    prev_name = nil
    table.each do |row|
      if(row.css(name_css).length > 0)
        name = row.css(name_css).first.content.to_s.strip
        desc = row.css(val_css).last.content.to_s.strip
        
        name = proper_start(just_alphanumeric(no_leading_spaces(no_tags(name))))
        desc = no_leading_spaces(desc)
        
        unless desc.nil? or desc == "" then
          name = prev_name and desc = spec_hash[name] + ", #{desc}" if name.length == 0
          prev_name = name
          spec_hash[name] = desc
        end
        
      end
    end
    return spec_hash
  end
  
  def get_max_f str
    return nil if str.nil?
    strsplit = str.split(/[\s-]/).collect{|x| get_f x}.delete_if{|x| x.nil?}.sort
    myfloat =  strsplit.last if strsplit
    return myfloat
  end
  
  def get_min_f str
    return nil if str.nil?
    strsplit = str.split(/[\s-]/).collect{|x| get_f x}.delete_if{|x| x.nil? or x == 0}.sort
    myfloat =  strsplit.first if strsplit
    return myfloat
  end
  
  def maxres_from_res res
    return nil if res.nil?
    maxres = get_max_f(res)
    return maxres
  end
  
  # Returns the value of the given attribute
  # from the element matching the given css string
  # in the given Nokogiri HTML document.
  def scrape_att_via_css page, css_str, attname
    el = get_el page.css(css_str)
    # TODO deal with nils?
    att = el.attribute(attname).to_s
    return att
  end
  
  # Same as below but difft args
  def many_fields_to_one multfields, atts, prefix=false
      vals = []
      multfields.each do |field|
         anotherval = atts[field]
         if anotherval and not anotherval.empty? 
           anotherval = anotherval.strip
           anotherval = field + ": #{anotherval}" if prefix
           vals << anotherval
         end 
      end
      vals.delete_if {|x| x.empty?}
      return vals * "\; " unless vals.empty?
      return nil
  end

  # Puts all the values from several fields in ActiveRecord oldrec
  # to a single field in ActiveRecord newrec.
  # You can add a prefix to 'label' the subfields inside the new field.
  def multiple_fields_to_one multfields, newfield, oldrec, newrec, prefix=false
    vals = []
    multfields.each do |field|
       anotherval = oldrec.[]("#{field}")
       if anotherval and not anotherval.empty? 
         anotherval = anotherval.strip
         anotherval = field + ": #{anotherval}" if prefix
         vals << anotherval
       end 
    end
    vals.delete_if {|x| x.empty?}
    fill_in newfield, vals * "\; ", newrec unless vals.empty?
  end
  
  # Returns the price integer: float * 100, rounded
  def get_price_i price_f
    return nil if price_f.nil? 
    return (price_f * 100).round
  end
  
  # Returns the price string
  def get_price_s price_f
    return nil if price_f.nil? 
    return (format "$%.2f", price_f)
  end
  
  # Returns the first integer in the string, or null
  def get_i str
    return nil if str.nil? or str.empty?
    return str.strip.match(/(\d+,)?\d+/).to_s.gsub(/,/,'').to_i
  end
  
  def proper_start str
    return "_#{str}" if str.match(/^[1-9]/) 
    return str
  end
  
  # Returns the first float in the string, or null
  # Eliminates thousand-separating commas
  def get_f str
    return nil if str.nil? or str.empty?
    myfloat =  str.strip.match(/(\d+,)?\d+(\.\d+)?/).to_s.gsub(/,/,'').to_f
    return nil if myfloat == 0 
    return myfloat
  end
  
  # Takes out any characters that are not alphanumeric. Spaces too.
  def just_alphanumeric label
   return nil if label.nil?
    return label.downcase.gsub(/ /,'').gsub(/[^a-zA-Z 0-9]/, "")
  end
  
  # Takes out stuff inside html-style tags.
  def no_tags label
    return label.gsub(/\<.+\/?\>/,'')
  end
  
  # Removes all leading & trailing spaces
  # Deals with weirdness found on TigerDirect website
  def no_leading_spaces str
    return str.gsub(/\302\240/,'').strip # What a hack.
  end
  
  # Useful method for getting an element if you're not
  # sure whether you have a Node or NodeSet. 
  # Returns nil for an empty NodeSet.
  def get_el x
    returnme = x.first || x
    return nil if returnme.class != Nokogiri::XML::Element
    return returnme
  end
  
  def get_b x
    return nil if x.nil?
    trues = ["yes", 'y',"1", 'true', 'optional']
    falses = ["no", 'n', "0", 'false']
    if trues.include? x.to_s.downcase.strip
      val = true
    elsif falses.include? x.to_s.downcase.strip
      val = false
    else
      val = nil
    end
    return val
  end
  

  # Logs to logfile or puts on screen 
  # if no logfile exists.
  def log str
    if @logfile
      @logfile.puts str
    else
      puts str
    end
  end
end