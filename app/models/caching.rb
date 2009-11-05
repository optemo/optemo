module CachingMemcached
  def findCachedCluster(id)
    if $cache
      begin
        c = $cache.get "C#{id}"
      rescue Memcached::NotFound
        c = $clustermodel.find(id)
        $cache.set "C#{id}", c
      end
    else
      c = $clustermodel.find(id)
    end
    c
  end
  
  def findCachedProduct(id)
    if $cache
      begin
        p = $cache.get "P#{id}"
      rescue Memcached::NotFound
        p = $model.find(id)
        $cache.set "P#{id}", p
      end
    else
      p = $model.find(id)
    end
    p
  end
end