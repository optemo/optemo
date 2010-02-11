module ScrapingHelper
  
  # Useful method for getting an element if you're not
  # sure whether you have a Node or NodeSet. 
  # Returns nil for an empty NodeSet or the first Node.
  def get_el x
    returnme = x.first || x
    return nil if returnme.class != Nokogiri::XML::Element
    return returnme
  end
  
  def get_text x
    returnme = x.first || x
    return nil if returnme.class != Nokogiri::XML::Element
    return returnme.text
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
  
  # Returns the value of the given attribute
  # from the element matching the given css string
  # in the given Nokogiri HTML document.
  def scrape_att_via_css page, css_str, attname
    el = get_el page.css(css_str)
    # TODO deal with nils?
    att = el.attribute(attname).to_s if el
    return att || nil
  end
  
end