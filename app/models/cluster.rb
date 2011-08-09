class Cluster
  require 'inline'
  attr :products
  attr :rep_id
  
  def initialize(products, rep_id)
    @products = products 
    @rep_id = rep_id
    if Rails.env.development?
      Site::Application::CLUSTER_CACHE[products.hash] = products.to_storage
    else
      Rails.cache.write("Cluster#{products.hash}", products.to_storage)
    end
  end
  
  def id
    products.hash
  end
  
  def self.cached(id)
    if Rails.env.development?
      p_ids = ComparableSet.from_storage Site::Application::CLUSTER_CACHE[id.to_i]
    else
      p_ids = ComparableSet.from_storage Rails.cache.read("Cluster#{id}")
    end
    #Cache miss
    #p_ids = SearchProduct.find_all_by_search_id(Session.product_type_int).map(&:product_id) unless p_ids
    debugger unless p_ids
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
      grouped_ids = products.classify{|p| cluster_ids.shift}
      (0..8).each do |i|
        product_ids = grouped_ids[i]
        next if product_ids.nil? || product_ids.empty? #In case a cluster is eliminated by the clustering algorithm
        debugger if products.map(&:id)[rep_ids[i]].nil?
        @children << Cluster.new(product_ids,products.map(&:id)[rep_ids[i]])
      end
      debugger if @children.map{|c| c.representative}.include?(nil)
      puts("*****######!!!!!!"+(finish-start).to_s)
    end
    @children
  end
  
 
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    unless @rep
      debugger if @rep_id.nil?
      @rep = Product.cached(@rep_id) 
    end
    @rep
  end
  
  def min(feature)
    if Session.continuous["cluster"].include?(feature)
      products.mapfeat(feature).compact.min
    end  
  end  
  
  def max(feature)
    if Session.continuous["cluster"].include?(feature)
      products.mapfeat(feature).compact.max
    end  
  end
  
  def cat_vals(feature)
    if Session.categorical["cluster"].include?(feature) 
      products.map{|p_id| CatSpec.cachemany([p_id], feature)}.flatten.uniq
    end
  end  
  
  def size
    products.size
  end
  
  def numclusters
    children.size
  end  
  
end
