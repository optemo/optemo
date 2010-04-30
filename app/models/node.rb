class Node < ActiveRecord::Base
  belongs_to :cluster
  belongs_to :product
  
  def self.byproduct(id)
    current_version = Session.current.version
    CachingMemcached.cache_lookup("NodesP#{current_version}#{id}"){find_all_by_product_id_and_version_and_product_type(id, current_version, $product_type)}
  end
  
  def self.bycluster(id)
    CachingMemcached.cache_lookup("Nodes#{id}"){find_all_by_cluster_id(id)}
  end
  
  #Not used, but here for completeness
  def self.cached(id)
    CachingMemcached.cache_lookup("Node#{id}"){find(id)}
  end
  
end
