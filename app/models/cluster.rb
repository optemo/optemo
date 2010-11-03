class Cluster
  require 'inline'
  attr :products
  
  def initialize(products)
    @products = products
    
    if Rails.env.development?
      Site::Application::CLUSTER_CACHE[products.hash.abs]=products
    else
      Rails.cache.write("Cluster#{products.hash.abs}", products)
    end
  end
  
  #Unique key for memcache lookup using BER-compressed integer
  def key
    products.pack("w*")
  end
  
  def id
    products.hash.abs
  end
  
  def self.cached(id)
    if Rails.env.development?
      p_ids = Site::Application::CLUSTER_CACHE[id.to_i]
    else
      p_ids = CachingMemcached.cache_lookup("Cluster#{id}")
    end
    #Cache miss
    #p_ids = Product
    Cluster.new(p_ids)
  end
  
  def self.findbychild(id,child_id = 0)
    cluster = self.cached(id)
    child = cluster.children[child_id] || cluster.children[0]
    child.products
  end
  
  #The subclusters
  def children
    unless @children
      #specs = Cluster.product_specs(products)
      start = Time.now
      cluster_ids = Kmeans.compute([9,products.length].min)
      finish = Time.now
      @children = Cluster.group_by_clusterids(products,cluster_ids).map{|product_ids|Cluster.new(product_ids)}
      puts("*****######!!!!!!"+(finish-start).to_s)
    end
    @children
  end
  
 
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    unless @rep
      utility_list = ContSpec.cachemany(products, "utility")
      @rep = Product.cached(products[utility_list.index(utility_list.max)])
    end
    @rep
  end
  
  def size
    products.size
  end
  
  def numclusters
    children.size
  end  
  
  def self.product_specs(p_ids)
    st = []
    Session.current.continuous["filter"].each{|f| st << ContSpec.cachemany(p_ids, f)}
    Session.current.categorical["filter"].each{|f|  st<<CatSpec.cachemany(p_ids, f)} 
    Session.current.binary["filter"].each{|f|  st << BinSpec.cachemany(p_ids, f)} 
    st.transpose 
  end 
 
  #Grouping products by cluster_ids
  def self.group_by_clusterids(product_ids, cluster_ids)
   product_ids.mygroup_by{|e,i|cluster_ids[i]}.sort{|a,b| b.length <=> a.length}
  end
end
