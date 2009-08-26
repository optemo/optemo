module ScrapingHelper

  @@general_ignore_list = ['id','created_at','updated_at']
  
  def self.general_ignore_list
    @@general_ignore_list
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
end