# Be careful when selecting a hash key that you don't cache data with identical keys. This is the #1 source of caching bugs so far.
module CachingMemcached
  def findCachedNode(nodeid)
    unless ENV['RAILS_ENV'] == 'development'
      current_version = Session.current.version
      Rails.cache.fetch("#{$nodemodel}#{current_version}#{nodeid}") { $nodemodel.find(nodeid) }
    else
      $nodemodel.find(nodeid)
    end
  end
  
  # The caching function really could probably be combined into fewer functions.
  # The reason not to is that it kept things simpler in terms of what to use as keys, search types, and so forth.
  def findCachedNodeByPID(productid)
    current_version = Session.current.version
    unless ENV['RAILS_ENV'] == 'development'
      Rails.cache.fetch("#{$nodemodel}ByPID#{current_version}#{productid}") { $nodemodel.find_by_product_id_and_version_and_region(productid, current_version, $region) }
    else
      $nodemodel.find_by_product_id_and_version_and_region(productid, current_version, $region)
    end    
  end
  
  def findCachedNodes(clusterid)
    unless ENV['RAILS_ENV'] == 'development'
      current_version = Session.current.version
      Rails.cache.fetch("#{$clustermodel.name}Nodes#{current_version}#{clusterid}") { $nodemodel.find_all_by_cluster_id(clusterid) }
    else
      $nodemodel.find_all_by_cluster_id(clusterid)
    end
  end
  
  def findAllCachedClusters(parentid)
    current_version = Session.current.version
    unless ENV['RAILS_ENV'] == 'development'
      Rails.cache.fetch("#{$clustermodel}s#{current_version}#{parentid}") { $clustermodel.find_all_by_parent_id_and_version_and_region(parentid, current_version, $region) }
    else
      $clustermodel.find_all_by_parent_id_and_version_and_region(parentid, current_version, $region)
    end
  end
  
  def findCachedCluster(clusterid)
    unless ENV['RAILS_ENV'] == 'development'
      current_version = Session.current.version
      Rails.cache.fetch("#{$clustermodel}#{current_version}#{clusterid}") { $clustermodel.find(clusterid) }
    else
      $clustermodel.find(clusterid)
    end
  end
  
  def findCachedProduct(productid)
    unless ENV['RAILS_ENV'] == 'development'
      current_version = Session.current.version
      Rails.cache.fetch("#{$model}#{current_version}#{productid}") { $model.find(productid) }
    else
      $model.find(productid)
    end
  end
  
  def findCachedProducts(product_ids)
    unless ENV['RAILS_ENV'] == 'development'
      current_version = Session.current.version
      Rails.cache.fetch("#{$model}s#{current_version}#{product_ids.join.hash}"){ $model.find(:all, :conditions => {:id => product_ids})}
    else
      $model.find(:all, :conditions => {:id => product_ids})
    end  
  end    
  
  # The following function is an interesting idea but it is currently not used.
  # The reason is that it's not clear what happens when read_multi fails to find all values in the cache.
#  def findCachedProducts(product_ids)
#    unless ENV['RAILS_ENV'] == 'development'
#      current_version = Session.current.version
#      Rails.cache.read_multi(product_ids.map{|p|$model.to_s + current_version.to_s + p.to_s})
#    else
#      $model.find(:all, :conditions => {:id => product_ids})
#    end  
#  end
  
  # This is a good idea, but right now the boostexter_combined_rules only works for cameras (March 23). Update this in future.
  def findCachedBoostexterRules(cluster_id)
    unless ENV['RAILS_ENV'] == 'development'
      current_version = Session.current.version
      Rails.cache.fetch("BoostexterCombinedRules#{current_version}#{cluster_id}"){ BoostexterCombinedRule.find(:all, :order => "weight DESC", :conditions => {"cluster_id" => cluster_id, "version" => Session.current.version})}
    else
      BoostexterCombinedRule.find(:all, :order => "weight DESC", :conditions => {"cluster_id" => cluster_id, "version" => Session.current.version})
    end
  end
 
 # Probably deprecated 
#  def findCachedTitles()
#    unless ENV['RAILS_ENV'] == 'development'
#      current_version = Session.current.version
#      Rails.cache.fetch("#{$model}#{current_version}Titles") { $model.find(:all, :select => "title").map{|c|c.title} }
#    else
#      $model.find(:all, :select => "title").map{|c|c.title}
#    end
#  end
end
