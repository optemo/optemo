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
  
  # This is a good idea, but right now the boostexter_combined_rules only works for cameras (March 23). Update this in future.
  def findCachedBoostexterRules(cluster_id)
    unless ENV['RAILS_ENV'] == 'development'
      current_version = Session.current.version
      Rails.cache.fetch("#{$rulemodel}s#{current_version}#{cluster_id}"){ $rulemodel.find(:all, :order => "weight DESC", :conditions => {"cluster_id" => cluster_id, "version" => Session.current.version})}
    else
      $rulemodel.find(:all, :order => "weight DESC", :conditions => {"cluster_id" => cluster_id, "version" => Session.current.version})
    end
  end

model::CategoricalFeaturesF.each {|name|
   f = DbFeature.new
   f.product_type = model.name
   f.feature_type = 'Categorical'
   f.name = name
   f.region = region
   f.categories = products.map{|c|c.send(name.intern)}.compact.uniq.join('*')
   f.save
 }
 model::ContinuousFeaturesF.each {|name|
   f = DbFeature.new
   f.product_type = model.name
   f.feature_type = 'Continuous'
   f.name = name
   f.region = region
   f.min = products.map{|c|c.send(name.intern)}.reject{|c|c.nil?}.sort[0]
   f.max = products.map{|c|c.send(name.intern)}.sort[-1]
  #f.hhigh = products.map{|c|c.send(name.intern)}.sort[products.count*0.85]
   f.high = products.map{|c|c.send(name.intern)}.sort[products.count*0.6]
   f.low = products.map{|c|c.send(name.intern)}.sort[products.count*0.4]
  #f.llow = products.map{|c|c.send(name.intern)}.sort[products.count*0.15]
   f.save
 }
 model::BinaryFeaturesF.each {|name|
   f = DbFeature.new
   f.product_type = model.name
   f.feature_type = 'Binary'
   f.name = name
   f.region = region
   f.save
 }
end
