# The part of DatabaseHelper which deals with
# filling in attributes for a given record
module DatabaseHelper

  # Does fill_in_missing on all name => value 
  # pairs in the hash
  def fill_in_all_missing hsh, rec, ignorelist=[]
    hsh.each{ |name,val| 
      fill_in_missing(name, val, rec, ignorelist) 
    }
  end
  
  # Does fill_in on all attribute name => value 
  # pairs in the hash
  def fill_in_all hsh, rec, ignorelist=[]
    hsh.each{ |name,val| fill_in name, val, rec, ignorelist }
  end
  
  # When the element exists, fills in the 
  # specified attribute of the specified record
  # with the text inside the element.
  def fill_in_optional name, el, record
    fill_in( name , el.text, record )if el
  end
  
  # Fills in value only if there is not yet a 
  # value for this attribute
  def fill_in_missing(name, val, rec, ignorelist=[])
    if !rec.attribute_present? name or rec.[](name).to_s.strip==''
      fill_in(name, val, rec, ignorelist)
    end
  end
  
  # Fills in value for attribute in record.
  # Cleverly avoids cases with nonexistent things.
  def fill_in name, desc, record, ignorelist=[]
    ignore = ignorelist + $general_ignore_list     
    
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