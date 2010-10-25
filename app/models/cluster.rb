class Cluster
  attr :products
  
  def initialize(products)
    @products = products
  end
  
  #Unique key for memcache lookup using BER-compressed integer
  def key
    products.pack("w*")
  end
  
  def id
    products.hash
  end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Cluster#{id}"){find(id)}
  end
  
  #The subclusters
  def children
    unless @children
      specs = Cluster.product_specs(products.map(&:id))
      #need to prepare specs
      debugger if specs != specs.compact
      cluster_ids = Cluster.kmeans(9,specs)
      @children = Cluster.group_by_clusterids(products,cluster_ids).map{|product_ids|Cluster.new(product_ids)}
    end
    @children
  end
  
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    unless @rep
      utility_list = ContSpec.cachemany(products.map(&:id), "utility")
      @rep = products[utility_list.index(utility_list.max)]
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

# converts categorical spec values to binary arrays
  def self.standardize_cat_data(specs)
    specs = specs.transpose
    #cont_size=3
    #cats = ["brand"]
    cont_size = Session.current.continous["filter"].size
    Session.current.categorical["filter"].each_index do |i|
      vals = specs[i+cont_size].uniq
      t=0
      specs[i+cont_size].each do |v| 
            cat = [0]*vals.size
            cat[vals.index(v)] = 1
            specs[i+cont_size][t]=cat
            t+=1  
      end      
    end
    specs = specs.transpose
    specs.map{|p| p.flatten}  
  end  
    
  #   
  def self.standardize_cont_data(specs)
    mean_all = means(specs)
    var_all = self.get_mean_var(specs, mean_all)
    specs.each{|p| p.each_with_index{|v, i| p[i]=(v-mean_all[i])/var[i]}}
  end
  
  # finds the standard deviation for every dimension(feature)
  def self.get_var(specs, mean_all)
    count = specs.size
    var = []
    specs.each{|p| var << p.each_index{|i| i*i}.inject(:+)}
    debugger
    var.each_index{|i| var[i]=Math.sqrt((var[i]/count) - (mean_all[i]**2))}
    var_all
  end
  
  
  # regular kmeans function   
 def self.kmeans(number_clusters, specs, weights = nil)
    debugger if specs.first.nil?
    weights = [1]*specs.first.size if weights.nil?
    tresh = 0.000001
    mean_1 = self.seed(number_clusters, specs)
    mean_2 =[]
    labels = []
    dif = []
    begin
      mean_2 = mean_1 
      specs.each_index do |i| 
        mean_1.each_index do |c|
          dif[c] = self.distance(specs[i], mean_1[c])
        end
        labels[i] = dif.index(dif.min)
      end 
      mean_1= self.means(number_clusters, specs, labels)
      z=0.0;
      mean_1.each_index{|c| z+=self.distance(mean_1[c], mean_2[c])}
    end while z > tresh
    labels  
  end
  
  
  #selecting the initial cluster centers
  def self.seed(number_clusters, specs)
    m=[]  
    # The first points as cluster centers
    (0...number_clusters).each{|i| m[i] = specs[i]}
    m
  end
  
  
#  # Finding the mean of several points
#  # points is a nxd dimension array where n is the number of products and d is number of features
  def self.mean(points)
    points.transpose.map{|p| p.map{|x| x.to_f}.inject(:+)/p.size}
  end
  
  
  # Finding the means of all clusters
  def self.means(number_clusters, specs, labels)
      m=[]
      (0...number_clusters).each do |c| 
        inds = self.indices(labels, c) 
        specs_c =[] 
        inds.each{|i| specs_c.push(specs[i])} 
        m[c] = self.mean(specs_c)
      end  
      m
  end
  
  # Finds the indices in an array that match the given value
  def self.indices(array, value) 
    c=[]
    array.each_index{|i| c.push(i) if array[i]==value}
    c
  end  
 
  #Grouping products by cluster_ids
  def self.group_by_clusterids(product_ids, cluster_ids)
   product_ids.group_by{|i|cluster_ids[product_ids.index(i)]}.values.sort{|a,b| b.length <=> a.length}
  end
  
  #Euclidian distance function
  def self.distance(point1, point2)
    dist = 0
    point1.each_index do |i|
      diff = point1[i]-point2[i]
      dist += diff*diff
    end
    dist
  end
  
  
end
