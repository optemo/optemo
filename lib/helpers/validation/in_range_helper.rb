module InRangeHelper
    
    def in_range_ify! atthash
      atthash.each do |k,v|
        atthash[k] = nil if !in_range?(k,v)
      end
    end
    
    def all_in_range? atthash
      atthash.each do |k,v|
        return false unless in_range?(k,v)
      end
      return true
    end
    
    # This function doesn't work at the moment.
    def in_range? key, val
      return true if Session.current.product_type::ValidRanges[key].nil? or val.nil?
      return false unless val >= Session.current.product_type::ValidRanges[key][0] # should be above min
      return false unless val <= Session.current.product_type::ValidRanges[key][1] # should be below max
      return true
    end
end
