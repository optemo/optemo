class ContSpec < ActiveRecord::Base
  belongs_to :product
  attr_writer :cs
  
  # Get specs for a single item
  def self.cache(p_id, feat)
    CachingMemcached.cache_lookup("ContSpec#{feat}#{p_id}") do
      r = find_by_product_id_and_name(p_id, feat)
      r.value if r
    end
  end
  def self.cachemany(p_ids, feat)
    CachingMemcached.cache_lookup("ContSpecs#{feat}#{p_ids.join.hash}") do
      find(:all, :select => 'value', :conditions => ["product_id IN (?) and name = ?", p_ids, feat]).map(&:value)
    end
  end
  
  # This probably isn't needed anymore, but is a good example of how to do class caching if we want to do it in future.
  def self.featurecache(p_id, feat) 
    @@cs = {} unless defined? @@cs
    p_id = p_id.to_s
    unless @@cs.has_key?($product_type + p_id + feat)
      find_all_by_product_type($product_type).each {|f| @@cs[($product_type + f.product_id.to_s + f.name)] = f}
    end
    @@cs[($product_type + p_id + feat)]
  end
  
  def self.allMinMax(feat)
    CachingMemcached.cache_lookup("#{$product_type}MinMax-#{feat}") do
      all = ContSpec.allspecs(feat)
      [all.min,all.max]
    end
  end

  def self.allLow(feat)
    CachingMemcached.cache_lookup("#{$product_type}Low-#{feat}") do
      ContSpec.allspecs(feat).sort[products.count*0.4]
    end
  end

  def self.allHigh(feat)
    CachingMemcached.cache_lookup("#{$product_type}High-#{feat}") do
      ContSpec.allspecs(feat).sort[products.count*0.6]
    end
  end
  
  private

  def self.allspecs(feat)
    #ContSpec.find_all_by_name_and_product_type(feat,$product_type).map(&:value)
    id_array = Product.valid.instock.map{|p| p.id }
    #id_array = Session.current.search.acceptedProductIDs
    ContSpec.cachemany(id_array, feat)
  end
  
  # This is used for sorting an array of ContSpec objects.
  def <=>(other)
     return value <=> other.value
  end
end
