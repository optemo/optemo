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
end
