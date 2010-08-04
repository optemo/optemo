# The part of DatabaseHelper which deals with
# filling in attributes for a given record
module ParseAttributeHelper
  
  # Creates a record and fills in any fitting attributes
  # from the given attribute hash
  def create_record_from_attributes(atts)
    s = Session.current
    atts.reject! { |k,v| v.nil? or $general_ignore_list.include?(k) } # Get rid of nil values, and make sure nothing in the ignore list survives (id especially)
    attributes_for_spec_tables = atts.reject{|k,v| not ($AllSpecs.include?(k))} # These attributes are applicable to the current product_type
    attributes_for_product_activerecord = atts.reject{|k,v| not (Product.column_names.include?(k))} # These attributes are universal (brand, etc.)
    
    p = Product.new(attributes_for_product_activerecord)
    p.save
    activerecords_to_save = []
    # Need to check what is cont, cat, or bin, and create accordingly
    attributes_for_spec_tables.each do |k,v| 
      case
      when s.continuous["all"].include?(k)
        class_type = "ContSpec"
      when s.categorical["all"].include?(k)
        class_type = "CatSpec"
      when s.binary["all"].include?(k)
        class_type = "BinSpec"
      end
      s = class_type.constantize.new({:product_id => p.id, :name => k, :value => v, :product_type => Session.current.product_type})
      activerecords_to_save.push(s)
    end
    activerecords_to_save.each(&:save)
    p
  end
  
  # Fills in value for attribute in record
  def parse_and_set_attribute(name, desc, record, ignorelist=[])
    ignore = ignorelist + $general_ignore_list
    return if (not record.has_attribute?(name) or ignore.include?(name))
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