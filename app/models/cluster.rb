class Cluster
  require 'inline'
  attr :products
  attr :rep_id
  
  def initialize(products, rep_id)
    @products = products # necessary?
    #@rep_id = rep_id
    if Rails.env.development?
      Site::Application::CLUSTER_CACHE[products.hash.abs]=products
      #Site::Application::CLUSTER_CACHE[rep_id.hash.abs]=rep_id
    else
      Rails.cache.write("Cluster#{products.hash.abs}", products)
      #Rails.cache.write("Cluster#{rep_id.hash.abs}", rep_id)
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
    #p_ids = SearchProduct.find_all_by_search_id(Product.initial).map(&:product_id) unless p_ids
    debugger unless p_ids
    p_ids
  end
  
  #The subclusters
  def children
    unless @children
      start = Time.now
      cluster_ids_and_reps = Kmeans.compute(9,products.to_a)
      cluster_ids = cluster_ids_and_reps[0...products.size] 
      rep_ids = cluster_ids_and_reps[products.size...cluster_ids_and_reps.size]
      finish = Time.now
      @children = []
      products.classify{|p| cluster_ids.shift}.each_pair do |i,product_ids|
        next if product_ids.empty? #In case a cluster is eliminated by the clustering algorithm
        @children << Cluster.new(product_ids,rep_ids[i])
      end
      
      #@children = []
      #grouped_ids = Array.new(9){Array.new}
      #products.each do |product|
      #  grouped_ids[cluster_ids.shift] << product
      #end
      #grouped_ids.each_with_index do |product_ids, i| 
      #  next if product_ids.empty? #In case a cluster is eliminated by the clustering algorithm
      #  @children << Cluster.new(product_ids,products[rep_ids[i]])
      #end
      puts("*****######!!!!!!"+(finish-start).to_s)
    end
    @children
  end
  
 
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    unless @rep
      if !(Session.search.sortby.nil?) && Session.continuous["cluster"].include?(Session.search.sortby)
         fs = products.to_a.map(&Session.search.sortby.intern).compact
         if (Session.search.sortby =='price') 
           target = fs.min
         else
           target = fs.max
         end    
         @rep = Product.cached(products.to_a.find{|p| p.send(Session.search.sortby.intern) == target}.id) 
      else
         max_utility = products.map(&:utility).max
         @rep = Product.cached(products.to_a.find{|p|p.utility == max_utility}.id)
      end  
    end
    @rep
  end
  def min(feature)
    if Session.continuous["cluster"].include?(feature)
      products.map(&feature.intern).compact.min
    end  
  end  
  
  def max(feature)
    if Session.continuous["cluster"].include?(feature)
      products.map(&feature.intern).compact.max
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
