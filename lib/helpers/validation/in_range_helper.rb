module InRangeHelper
    
    def in_range_ify! atthash, model=$model
      atthash.each do |k,v|
        atthash[k] = nil if !in_range?(k,v,model)
      end
    end
    
    def all_in_range? atthash, model=$model
      atthash.each do |k,v|
        return false unless in_range?(k,v,model)
      end
      return true
    end
    
    def in_range? key, val, model=$model
      return true if model::ValidRanges[key].nil? or val.nil?
      return false unless val >= model::ValidRanges[key][0] # should be above min
      return false unless val <= model::ValidRanges[key][1] # should be below max
      return true
    end
end