# Be careful when selecting a hash key that you don't cache data with identical keys. This is the #1 source of caching bugs so far.
module CachingMemcached
  def cache_lookup(key)
    Rails.env.development?
      #current_version = Session.current.version
      Rails.cache.fetch(key) { yield }
    else
      yield
    end
  end
  
  def minSpec(feat)
    cache_lookup("ProdMin-#{feat}"){ContSpec.find_all_by_name_and_product_type(feat,$product_type).map(&:value).min}
  end
  
  def maxSpec(feat)
    cache_lookup("ProdMax-#{feat}"){ContSpec.find_all_by_name_and_product_type(feat,$product_type).map(&:value).max}
  end
  
  def lowSpec(feat)
    cache_lookup("ProdLow-#{feat}"){ContSpec.find_all_by_name_and_product_type(feat,$product_type).map(&:value).sort[products.count*0.4]}
  end
  
  def highSpec(feat)
    cache_lookup("ProdHigh-#{feat}"){ContSpec.find_all_by_name_and_product_type(feat,$product_type).map(&:value).sort[products.count*0.6]}
  end
  
  # This is a good idea, but right now the boostexter_combined_rules only works for cameras (March 23). Update this in future.
  def findCachedBoostexterRules(cluster_id)
    cache_lookup("#{$rulemodel}s#{current_version}#{cluster_id}"){$rulemodel.find(:all, :order => "weight DESC", :conditions => {"cluster_id" => cluster_id, "version" => Session.current.version})}
  end
end
