class Node < ActiveRecord::Base
  belongs_to :cluster
  belongs_to :product
  has_many :cont_specs, :through => :product
  has_many :bin_specs, :through => :product
  has_many :cat_specs, :through => :product

  def self.byproduct(id)
    current_version = Session.current.version
    CachingMemcached.cache_lookup("NodeP#{current_version}#{id}"){find_by_product_id_and_version(id, current_version)}
  end
  
  def self.bycluster(id)
    CachingMemcached.cache_lookup("Nodes#{id}"){find_all_by_cluster_id(id)}
  end
  
  #Not used, but here for completeness
  def self.cached(id)
    CachingMemcached.cache_lookup("Node#{id}"){find(id)}
  end
  
end
