module ScrapingHelper
  
  @general_ignore_list = ['id','created_at','updated_at']
  
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
  
  def maxres_from_res res
    return nil if res.nil?
    maxres = res.scan(/\d+/).collect{|x|x.to_i}.sort.last
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
    #return nil if myfloat == 0 
    return myfloat
  end
  
  # Takes out any characters that are not alphanumeric. Spaces too.
  def just_alphanumeric label
    return label.downcase.gsub(/ /,'').gsub(/[^a-zA-Z 0-9]/, "")
  end
  
  
  # Takes out any characters that are not alphanumeric. Spaces too.
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
  
  def fill_in_all hsh, rec
    hsh.each{ |name,val| fill_in name, val, rec }
  end
  
  # When the element exists, fills in the 
  # specified attribute of the specified record
  # with the text inside the element.
  def fill_in_optional name, el, record
    fill_in( name , el.text, record )if el
  end
  
  # Fills in value for attribute in record.
  # Cleverly avoids cases with nonexistent things.
  def fill_in name, desc, record
        
    unless record.has_attribute? name
      @logfile.puts "#{name} missing from attribute list"
      return
    end
    
    return if desc.nil?
    
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