class ContSpec < ActiveRecord::Base
  belongs_to :product
  attr_writer :cs
  
  # These are both included because testing needs to be done in comparing featurecache to cached
  # Due to the high number of hits per request, having this cache in memory might be the one place to break
  # from the pattern of using only memcached
#  def self.cached(p_id, feat)
  def self.cache(p_id, feat)
    CachingMemcached.cache_lookup("ContSpec#{feat}#{p_id}"){find_by_product_id_and_name(p_id, feat)}
  end
  def self.cachemany(p_ids, feat)
    CachingMemcached.cache_lookup("ContSpecs#{feat}#{p_ids.join.hash}") do
      find(:all, :select => 'value', :conditions => ["product_id IN (?) and name = ?", p_ids, feat]).map(&:value)
    end
  end
  
  # This probably isn't needed anymore.
  def self.featurecache(p_id, feat) 
    # Caching is better using class variable due to thousands of hits per request? Test this. Memcache for now; ie., this is dead code
    # Hash key must be based on model type, id, and feature name together to guarantee uniqueness.
    
    @@cs = {} unless defined? @@cs
    p_id = p_id.to_s
    unless @@cs.has_key?($product_type + p_id + feat)
      find_all_by_product_type($product_type).each {|f| @@cs[($product_type + f.product_id.to_s + f.name)] = f}
    end
    @@cs[($product_type + p_id + feat)]
  end
  
  def self.allMin(feat)
    CachingMemcached.cache_lookup("#{$product_type}Min-#{feat}") do
      ContSpec.allspecs(feat).min
    end
  end

  def self.allMax(feat)
    CachingMemcached.cache_lookup("#{$product_type}Max-#{feat}") do
      ContSpec.allspecs(feat).max
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
    ContSpec.cachemany(id_array, feat)
  end
end
