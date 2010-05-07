# Be careful when selecting a hash key that you don't cache data with identical keys. This is the #1 source of caching bugs so far.
module CachingMemcached
  def self.cache_lookup(key)
    unless Rails.env.development?
      Rails.cache.fetch(key) { yield }
    else
      yield
    end
  end

  def self.minSpec(feat)
    CachingMemcached.cache_lookup("#{$product_type}Min-#{feat}") do
      CachingMemcached.contspecs(feat).min
    end
  end

  def self.maxSpec(feat)
    CachingMemcached.cache_lookup("#{$product_type}Max-#{feat}") do
      CachingMemcached.contspecs(feat).max
    end
  end

  def self.lowSpec(feat)
    CachingMemcached.cache_lookup("#{$product_type}Low-#{feat}") do
      CachingMemcached.contspecs(feat).sort[products.count*0.4]
    end
  end

  def self.highSpec(feat)
    CachingMemcached.cache_lookup("#{$product_type}High-#{feat}") do
      CachingMemcached.contspecs(feat).sort[products.count*0.6]
    end
  end

  private

  def self.contspecs(feat)
    #ContSpec.find_all_by_name_and_product_type(feat,$product_type).map(&:value)
    id_array = Product.valid.instock.map{|p| p.id }
    ContSpec.cachemany(id_array, feat)
  end
end
