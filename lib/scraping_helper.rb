module ScrapingHelper
  
  @@general_ignore_list = ['id','created_at','updated_at']
  
  @@float_rxp = /(\d+,)?\d+(\.\d+)?/
  
  @@sep = '!@!'
  
  def self.sep
    return @@sep
  end
  
  def generic_printer_cleaning_code atts
    
    atts['ppm'] = get_max_f(atts['ppm'])
    atts['ppmcolor'] = get_max_f(atts['ppmcolor'])
    atts['ttp'] = get_min_f(atts['ttp'])
    
    atts['paperinput'] = (atts['paperinput'] || '').split(@@sep).collect{|x| parse_max_num_pages(x)}.reject{|x| x.nil?}.max 
    debugger if atts['paperinput'] and atts['paperinput'] < 100
    
    atts['brand'] = atts['brand'].gsub(/\(.+\)/,'').strip if atts['brand']
    # Model:
    if (atts['model'].nil? or atts['model'] == atts['mpn']) and atts['title']
      # TODO combine with other model cleaner code
      dirty_model_str = atts['title'].match(/.+\sprinter/i).to_s.gsub(/ - /,'') 
      
    end
    if atts['model']
      atts['model'].gsub!(/(mfp|multi-?funct?ion|duplex|faxcent(er|re)|workcent(re|er)|mono|laser|dig(ital)?|color|(black(\sand\s|\s?\/\s?)white)|network|all(\s?-?\s?)in(\s?-?\s?)one)\s?/i,'')
      atts['model'].gsub!(/printer\s?/i,'')
      atts['model'].gsub!(/#{atts['brand']}\s?/i,'')
      # TODO
      (@brand_alternatives || []).each do |alts|
        if alts.include? atts['brand'].downcase
          alts.each do |altbrand|
            atts['model'].gsub!(/#{altbrand}\s?/i,'')
          end
        end
      end
      ($series || []).each do |ser|
        atts['model'].gsub!(/#{ser}\s?/i,'')
      end
      atts['model'].strip!
    end
    
    
    atts['model'] = atts['mpn'] if atts['model'].nil? or atts['model'] ==''
    
    # Resolution
    atts['resolution'] = atts['resolution'].scan(/\d+\s?x\s?\d+/i).uniq * ', '
    atts['resolutionmax'] = maxres_from_res atts['resolution']
        
    # Item height, width, depth
    (atts['dimensions'] || "").split('x').each do |dim| 
      atts['itemlength'] = get_f(dim) if dim.include? 'D' and !atts['itemlength']
      atts['itemwidth'] = get_f(dim) if dim.include? 'W' and !atts['itemwidth']
      atts['itemheight'] = get_f(dim) if dim.include? 'H' and !atts['itemheight']
    end
    
    # For the OFFERING
    atts['priceint'] = get_price_i( get_f((atts['pricestr'] || '').gsub(/\*/,'')) )
    atts['pricestr'].strip! if atts['pricestr']
    
    # For the PRODUCT
    if atts['region'] == 'CA' then suffix = '_ca' else suffix='' end
    atts["listpricestr#{suffix}"].strip! if atts["listpricestr#{suffix}"]
    atts["listpriceint#{suffix}"] = get_price_i( get_f atts["listpriceint#{suffix}"] )
    
    atts['condition'] = "Refurbished" if (atts['title']||'').match(/refurbished/i) 
    atts['condition'] = "OEM" if (atts['title']||'').match(/oem/i)
    
    # Booleans
    atts['printserver'] = clean_bool(atts['printserver'])
    atts['scanner'] = clean_bool(atts['scanner'])
    
    # TODO clean paperinput
    return atts
  end
  
  def clean_bool dirty_vals
    vals = []
    (dirty_vals || '').split(@@sep).each { |dirty_val| 
      val = get_b(dirty_val)
      if val.nil? and !dirty_val.nil?
        val = dirty_val.match(/(not applicable|n\/a|not available)/i).nil?
      end
      vals << val
    }
    if vals.empty? or vals.uniq == [nil]
      return nil
    elsif vals.include? true
      return true
    else
      return false
    end
  end
  
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
      param_names << param if str.match(/#{param}/)
    end
    
    param_names << 'ttp' if str.match(/(firstpageoutputtime|timeto(firstpage|print))/)
    param_names << 'ppm' if str.match(/print(ing)?speed/)  
    param_names << 'brand' if str.match(/manufacture(d|r$)/)
    param_names << 'packageweight' if str.match(/shippingweight/)
    param_names << 'listpricestr' if str.match(/originalprice/)
    param_names << 'mpn' if str.match(/mfgpartn(o|um)/)
    param_names << 'paperinput' if str.match(/(input|sheet|paper)capacity/)
    param_names << 'paperoutput' if str.match(/outputcapacity/)
    param_names << 'resolution' if str.match(/print(ing)?quality/)
    param_names << 'papersize' if str.match(/mediasize/)
    param_names << 'connectivity' if str.match(/printerinterface/)
    param_names << 'itemwidth' if str.match(/width/) # TODO
    param_names << 'packagewidth' if str.match(/width/) # TODO
    param_names << 'printserver' if str.match(/(network|server)/)
    param_names << 'colorprinter' if str.match(/(colou?r|printtechnology|printeroutput)/)
    param_names << 'dimensions' if str.match(/size/)
    
    if str.match(/colou?r/)
      param_names << 'ppmcolor' if param_names.include? 'ppm'
    end
    
    param_names << 'dimensions' if str.match(/dimensions/)
    
    return param_names
  end
  
  def self.general_ignore_list
    @@general_ignore_list
  end
  
  def download_img url, folder, fname=nil
    return nil if url.nil? or url.empty?
    return url if url.include?(folder)
    filename = fname || url.split('/').pop
    ret = "/#{folder}/#{filename}"
    begin
    f = open("/optemo/site/public/#{folder}/#{filename}","w").write(open(url).read)
    rescue OpenURI::HTTPError => e
      ret = nil
      puts "#{e.type} #{e.message}"
    end
    ret
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
    trues = ["yes","1"]
    falses = ["no", "0"]
    if trues.include? x.to_s.downcase.strip
      val = true
    elsif falses.include? x.to_s.downcase.strip
      val = false
    else
      val = nil
    end
    return val
  end
  
  # Fill in only nils!
  def fill_in_all_missing hsh, rec, ignorelist=[]
    hsh.each{ |name,val| 
      fill_in_missing(name, val, rec, ignorelist) 
    }
  end
  
  def fill_in_all hsh, rec, ignorelist=[]
    hsh.each{ |name,val| fill_in name, val, rec, ignorelist }
  end
  
  # When the element exists, fills in the 
  # specified attribute of the specified record
  # with the text inside the element.
  def fill_in_optional name, el, record
    fill_in( name , el.text, record )if el
  end
  
  def fill_in_missing(name, val, rec, ignorelist=[])
    if !rec.attribute_present? name or rec.[](name).to_s.strip==''
      fill_in(name, val, rec, ignorelist)
    end
  end
  
  # Fills in value for attribute in record.
  # Cleverly avoids cases with nonexistent things.
  def fill_in name, desc, record, ignorelist=[]
    ignore = ignorelist + @@general_ignore_list     
    
    return unless record.has_attribute? name
    return if desc.nil?
    return if ignore.include?(name)
    case (record.class.columns_hash[name].type)
      when :integer
        val = get_i(desc.to_s)
      when :float
        val = get_f(desc.to_s)
      when :string
        val = desc.to_s.strip
      else
        val = desc
    end  
    record.update_attribute(name, val)
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