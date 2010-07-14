# The part of DatabaseHelper which deals with
# filling in attributes for a given record
module FillInHelper
  
  # Creates a record and fills in any fitting attributes
  # from the given attribute hash
  def create_record_from_attributes(atts)
    atts.reject! { |k,v| v.nil? or $general_ignore_list.include?(k) } # Get rid of nil values, and make sure nothing in the ignore list survives (id especially)
    attributes_for_spec_tables = atts.reject{|k,v| not ($AllSpecs.include?(k))} # These attributes are applicable to the current $product_type
    attributes_for_product_activerecord = atts.reject{|k,v| not (Product.column_names.include?(k))} # These attributes are universal (brand, etc.)
    
    # attributes for product_activerecord should probably come from Product.column_names

    p = Product.new(attributes_for_product_activerecord)
    p.save
    activerecords_to_save = []
    # Need to check what is cont, cat, or bin, and create accordingly
    attributes_for_spec_tables.each do |k,v| 
      case
      when $Continuous["all"].include?(k)
        class_type = "ContSpec"
      when $Categorical["all"].include?(k)
        class_type = "CatSpec"
      when $Binary["all"].include?(k)
        class_type = "BinSpec"
      end
      s = class_type.constantize.new({:product_id => p.id, :name => k, :value => v, :product_type => $product_type})
      activerecords_to_save.push(s)
    end
    activerecords_to_save.each(&:save)
    p
  end

  # Returns a hash of only those attributes which :
  # 1. have non-nil values
  # 2. are 'applicable to' (exist for) the given model 
  # (eg displaysize doesn't exist for Cartridge)
  # 3. are not in the given ignore list or the usual ignore list

  # Does fill_in_missing on all name => value 
  # pairs in the hash
  def fill_in_all_missing(hash, rec, ignorelist=[])
    hash.each{ |name,val| fill_in_missing(name, val, rec, ignorelist) }
  end
  
  # Does fill_in on all attribute name => value 
  # pairs in the hash
  def fill_in_all(hash, rec, ignorelist=[])
    hash.each{ |name,val| fill_in(name, val, rec, ignorelist) }
  end
  
  # When the element exists, fills in the 
  # specified attribute of the specified record
  # with the text inside the element.
  def fill_in_optional(name, el, record)
    fill_in(name, el.text, record) if el
  end
  
  # Fills in value only if there is not yet a 
  # value for this attribute
  def fill_in_missing(name, val, rec, ignorelist=[])
    fill_in(name, val, rec, ignorelist) if !rec.attribute_present? name or rec.[](name).to_s.strip==''
  end
  
  # Default is to fill in unless the value is nil
  def fill_in(name, desc, record, ignorelist=[])
    return nil if desc.nil?
    fill_in_forced(name, desc, record, ignorelist)
  end
  
  # Fills in value for attribute in record even if
  # value is nil
  def fill_in_forced(name, desc, record, ignorelist=[])
    ignore = ignorelist + $general_ignore_list     

    return unless record.has_attribute?(name)
    return if ignore.include?(name)
    if !desc.nil?
      case (record.class.columns_hash[name].type)
        when :integer
          val = get_i(desc.to_s)
        when :float
          val = get_f(desc.to_s)
        when :string
          val = desc
          val = desc.to_s.strip unless name == 'pricehistory'
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
    record[name] = val
    record
  end
end