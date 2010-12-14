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
      cluster_ids = Kmeans.compute([9,products.length].min,products)
      finish = Time.now
      @children = Cluster.group_by_clusterids(products,cluster_ids).map{|product_ids|Cluster.new(product_ids)}
      puts("*****######!!!!!!"+(finish-start).to_s)
    end
    @children
  end
  
 
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    unless @rep
      unless Session.current.search.sortby == "Price"
        # The default is to sort by utility. At the moment, the alternative is price sorting.
        utility_list = ContSpec.cachemany(products, "utility")
        # If you see an error here due to utility_list being nil, consider running "rake calculate_factors"
        @rep = Product.cached(products[utility_list.index(utility_list.max)])
      else
        price_list = ContSpec.cachemany(products, "price")
        @rep = Product.cached(products[price_list.index(price_list.min)])
      end
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
