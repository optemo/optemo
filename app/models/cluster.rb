class Cluster
  require 'inline'
  attr :products
  attr :rep_id
  
  def initialize(products, rep_id)
    @products = products # necessary?
    @rep_id = rep_id
    if Rails.env.development?
      Site::Application::CLUSTER_CACHE[products.hash.abs]=products
      Site::Application::CLUSTER_CACHE[rep_id.hash.abs]=rep_id
    else
      Rails.cache.write("Cluster#{products.hash.abs}", products)
      Rails.cache.write("Cluster#{rep_id.hash.abs}", rep_id)
    end
  end
  
  def id
    products.hash.abs
  end
  
  def self.cached(id)
    if Rails.env.development?
      p_ids = Site::Application::CLUSTER_CACHE[id.to_i]
    else
      p_ids = Rails.cache.read("Cluster#{id}")
    end
    #Cache miss
    p_ids = SearchProduct.find_all_by_search_id(Product.initial).map(&:product_id) unless p_ids

    p_ids
  end
  
  #The subclusters
  def children
    unless @children
      start = Time.now
      cluster_ids_and_reps = Kmeans.compute(9,products)
      cluster_ids = cluster_ids_and_reps[0...products.size] 
      rep_ids = cluster_ids_and_reps[products.size...cluster_ids_and_reps.size]
      finish = Time.now
      @children = []
      grouped_ids = Cluster.group_by_clusterids(products,cluster_ids)
      grouped_ids.each_with_index{|product_ids, i| @children << Cluster.new(product_ids,products[rep_ids[i]])}
      puts("*****######!!!!!!"+(finish-start).to_s)
    end
    @children
  end
 
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    unless @rep
      #@rep = Product.cached(rep_id)
      utilities = products.map{|p_id| ContSpec.featurecache(p_id, "utility")}.map(&:value)
      @rep = Product.cached(products[utilities.index(utilities.max)])
    end
    @rep
  end
  
  def size
    products.size
  end
  
  def numclusters
    children.size
  end  
  
  
  #Grouping products by cluster_ids
  def self.group_by_clusterids(product_ids, cluster_ids)
    product_ids.mygroup_by{|e,i|cluster_ids[i]}
  end
  
end
