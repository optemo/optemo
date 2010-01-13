# The part of DatabaseHelper which deals with
# filling in attributes for a given record
module FillInHelper
  
  # Creates a record and fills in any fitting attributes
  # from the given attribute hash
  def create_record_from_atts atts, recclass=$model
    atts_to_copy = only_overlapping_atts atts, recclass
    p = recclass.new(atts_to_copy)
    p.save
    return p
  end

  # Returns a hash of only those attributes which :
  # 1. have non-nil values
  # 2. are 'applicable to' (exist for) the given model 
  # (eg displaysize doesn't exist for Cartridge)
  # 3. are not in the given ignore list or the usual ignore list
  def only_overlapping_atts atts, other_recs_class, ignore_list=[]
    big_ignore_list = ignore_list + $general_ignore_list
    overlapping_atts = atts.reject{ |x,y| 
      y.nil? or not other_recs_class.column_names.include? x \
      or big_ignore_list.include? x }
    return overlapping_atts
  end

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
  
  # Default is to fill in unless the value is nil
  def fill_in name, desc, record, ignorelist=[]
    return if desc.nil?
    fill_in_forced name, desc, record, ignorelist
  end
  
  # Fills in value for attribute in record even if
  # value is nil
  def fill_in_forced name, desc, record, ignorelist=[]
    ignore = ignorelist + $general_ignore_list     
    
    return unless record.has_attribute? name
    return if ignore.include?(name)
    if !desc.nil?
      case (record.class.columns_hash[name].type)
        when :integer
          val = get_i(desc.to_s)
        when :float
          val = get_f(desc.to_s)
        when :string
          val = desc.to_s.strip
        when :datetime
          val = DateTime.parse(desc.to_s)
        when :date
          val = Date.parse(desc.to_s)
        else
          val = desc
      end  
    else
      val = nil
    end
    record.update_attribute(name, val)
  end
end