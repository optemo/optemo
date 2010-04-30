# Be careful when selecting a hash key that you don't cache data with identical keys. This is the #1 source of caching bugs so far.
module CachingMemcached
  def self.cache_lookup(key)
    unless Rails.env.development?
      #current_version = Session.current.version
      Rails.cache.fetch(key) { yield }
    else
      yield
    end
  end
  
  def self.minSpec(feat)
    CachingMemcached.cache_lookup("ProdMin-#{feat}") do
      CachingMemcached.contspecs(feat).min
    end
  end
  
  def self.maxSpec(feat)
    CachingMemcached.cache_lookup("ProdMax-#{feat}") do
      CachingMemcached.contspecs(feat).max
    end
  end
  
  def self.lowSpec(feat)
    CachingMemcached.cache_lookup("ProdLow-#{feat}") do
      CachingMemcached.contspecs(feat).sort[products.count*0.4]
    end
  end
  
  def self.highSpec(feat)
    CachingMemcached.cache_lookup("ProdHigh-#{feat}") do
      CachingMemcached.contspecs(feat).sort[products.count*0.6]
    end
  end
  
  # This is a good idea, but right now the boostexter_combined_rules only works for cameras (March 23). Update this in future.
  def self.findCachedBoostexterRules(cluster_id)
    CachingMemcached.cache_lookup("#{$rulemodel}s#{current_version}#{cluster_id}") do
      $rulemodel.find(:all, :order => "weight DESC", :conditions => {"cluster_id" => cluster_id, "version" => Session.current.version})
    end
  end
  
  private
  
  def self.contspecs(feat)
    ContSpec.find_all_by_name_and_product_type(feat,$product_type).map(&:value)
  end
end
