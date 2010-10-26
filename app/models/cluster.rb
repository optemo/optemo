class Cluster
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
      Cluster.new(Site::Application::CLUSTER_CACHE[id.to_i])
    else
      Cluster.new(CachingMemcached.cache_lookup("Cluster#{id}"))
    end
  end
  
  def self.findbychild(id,child_id = 0)
    cluster = self.cached(id)
    child = cluster.children[child_id] || cluster.children[0]
    child.products
  end
  
  #The subclusters
  def children
    unless @children
      
      specs = Cluster.product_specs(products)
      start = Time.now
      cluster_ids = Cluster.kmeans([9,products.length].min,specs)
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
    #2.44
    weights = [1]*specs.first.size if weights.nil?
    thresh = 0.000001
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
    end while z > thresh
    labels  
  end
  
  #Inloop calculation
  #def self.kmeans(number_clusters, specs, weights = nil)
  #  #2.48
  #  weights = [1]*specs.first.size if weights.nil?
  #  thresh = 0.000001
  #  mean_1 = self.seed(number_clusters, specs)
  #  mean_2 =[]
  #  labels = []
  #  dif = []
  #  spec_length = specs.first.size
  #  begin
  #    mean_2 = mean_1 
  #    mean_1_count = Array.new(number_clusters,0)
  #    mean_1 = Array.new(number_clusters){|a|[0.0]*spec_length}
  #    
  #    specs.each_index do |i| 
  #      mean_2.each_index do |c|
  #        dif[c] = self.distance(specs[i], mean_2[c])
  #      end
  #      labels[i] = dif.index(dif.min)
  #      mean_1[labels[i]].each_index {|f|mean_1[labels[i]][f] += specs[i][f]}
  #      mean_1_count[labels[i]] += 1
  #    end 
  #    mean_1.each_with_index{|cluster_sum,i|mean_1[i] = cluster_sum.map{|f|f/mean_1_count[i]}}
  #    #mean_1= self.means(number_clusters, specs, labels)
  #    z=0.0;
  #    mean_1.each_index{|c| z+=self.distance(mean_1[c], mean_2[c])}
  #  end while z > thresh
  #
  #  labels  
  #end
  
#inline do |builder|
#  builder.c "
#      
#  static VALUE kmeans_c(VALUE _points, VALUE n, VALUE d, VALUE cluster_n){
#    VALUE* points_a = RARRAY_PTR(_points);
#    int nn = NUM2INT(n);
#    int dd = NUM2INT(d);
#    int k = NUM2INT(cluster_n);
#    double DBL_MAX = 10000000.0;
#    double t = 0.00001;
#    
#    VALUE labels_r = rb_ary_new2(nn);
#    int i, j, h;
#    double** data = malloc(sizeof(double*)*nn);
#    double* means = malloc(sizeof(double)*dd);
#  //  int* labels = malloc(sizeof(int)*nn);
#    for (j=0; j<dd; j++) means[j]=0.0;
#    for (i=0; i<nn; i++) data[i] = malloc(sizeof(double)*dd);    
#    for (i=0; i<nn; i++){
#      for (j=0; j<dd; j++) {   
#         data[i][j]= NUM2DBL(points_a[i*dd+j]);
#      }
#    }
#        
#    int *counts = (int*)calloc(k, sizeof(int)); //(int*)calloc(k, sizeof(int)); /* size of each cluster */
#    double old_error, error = DBL_MAX; /* sum of squared euclidean distance */
#    double** centroids = malloc(sizeof(double*)*k);
#    for (i=0; i<k; i++) centroids[i]= malloc(sizeof(double)*dd);
#    double **c = (double**)calloc(k, sizeof(double*));
#    double **c1 = (double**)calloc(k, sizeof(double*)); /* temp centroids */
#    int *labels = (int*)calloc(nn, sizeof(int)); 
#        
#  for (h = i = 0; i < k; h += nn / k, i++) {
#     c1[i] = (double*)calloc(dd, sizeof(double));
#     c[i] = (double*)calloc(dd, sizeof(double));
#     /* pick k points as initial centroids */
#     for (j = dd; j-- > 0; c[i][j] = data[h][j]);
#  }
#
#  /****
#  ** main loop */
#
#  do {
#     /* save error from last step */
#     old_error = error, error = 0;
#
#     /* clear old counts and temp centroids */
#     for (i = 0; i < k; counts[i++] = 0) {
#        for (j = 0; j < dd; c1[i][j++] = 0);
#     }
#
#     for (h = 0; h < nn; h++) {
#        /* identify the closest cluster */
#        double min_distance = DBL_MAX;
#        for (i = 0; i < k; i++) {
#           double distance = 0;
#           for (j = dd; j-- > 0; distance += (data[h][j] - c[i][j]) * (data[h][j] - c[i][j])) ;
#           if (distance < min_distance) {
#              labels[h] = i;
#              min_distance = distance;
#           }
#        }
#        /* update size and temp centroid of the destination cluster */
#        for (j = dd; j-- > 0; c1[labels[h]][j] += data[h][j]);
#        counts[labels[h]]++;
#        /* update standard error */
#        error += min_distance;
#     }
#
#     for (i = 0; i < k; i++) { /* update all centroids */
#        for (j = 0; j < dd; j++) {
#           c[i][j] = counts[i] ? c1[i][j] / counts[i] : c1[i][j];
#        }
#     }
#
#  } while (((error - old_error)*(error - old_error)) > t);
#
#  for (j=0; j<dd; j++){
#      rb_ary_store(labels_r, j, INT2NUM(labels[j]));
#  }
#  return labels_r;
#}
#  "
#end
  
  
  
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
    #2.8s
    #points.transpose.map{|p| p.map{|x| x.to_f}.inject(:+)/p.size}
    #
    #2.69, 2.71
    s = points.size.to_f
    points.transpose.map{|p| p.inject(:+)/s}
    #
    #FAIL - modifies points
    #p = points.dup
    #s = points.size.to_f
    #p.inject{|result, element| result.each_index{|i|result[i]+=element[i]}}.map{|i|i/s}
    #
    #FAIL - modifies points
    #s = points.size.to_f
    #res = points.pop
    #while (c = points.pop)
    #  res.each_index{|i|res[i] += c[i]}
    #end
    #res.map{|i|i/s}
    #
    #2.86, 2.93
    #s = points.size.to_f
    #res = [0]*points.first.size
    #points.each do |p|
    #  p.each_index{|i|res[i] += p[i]}
    #end
    #res.map{|i|i/s}
  end
  
  # Finding the means of all clusters
  # Group the specs based on their labels and within each group, find their mean
  def self.means(number_clusters, specs, labels)
    #2.48, 2.58, 2.42 (2.52,2.44,2.55) ((2.41, 2.48, 2.41))
    specs.mygroup_by{|e,i|labels[i]}.map{|s|self.mean(s)}
    
    #2.76,2.7
    #m=[]
    #(0...number_clusters).each do |c| 
    #  inds = self.indices(labels, c) 
    #  specs_c =[] 
    #  inds.each{|i| specs_c.push(specs[i])} 
    #  m[c] = self.mean(specs_c)
    #end  
    #m
  end
  
  # Finds the indices in an array that match the given value
  def self.indices(array, value) 
    c=[]
    array.each_index{|i| c.push(i) if array[i]==value}
    c
  end  
 
  #Grouping products by cluster_ids
  def self.group_by_clusterids(product_ids, cluster_ids)
   #product_ids.group_by{|i|cluster_ids[product_ids.index(i)]}.values.sort{|a,b| b.length <=> a.length}
   #2.51,2.45, 2.4
   product_ids.mygroup_by{|e,i|cluster_ids[i]}.sort{|a,b| b.length <=> a.length}
  end
  
  #Euclidian distance function
  def self.distance(point1, point2)
    #4.11
    #[point1,point2].transpose.map do |p|
    #  t=(p[1]-p[0])
    #  t*t
    #end.sum
    
    #2.43
    dist = 0
    point1.each_index do |i|
      diff = point1[i]-point2[i]
      dist += diff*diff
    end
    dist
  end
 
  #Grouping products by cluster_ids
  def self.group_by_clusterids(product_ids, cluster_ids)
   #product_ids.group_by{|i|cluster_ids[product_ids.index(i)]}.values.sort{|a,b| b.length <=> a.length}
   #2.51,2.45, 2.4
   product_ids.mygroup_by{|e,i|cluster_ids[i]}.sort{|a,b| b.length <=> a.length}
  end
  
  #Euclidian distance function
  def self.distance(point1, point2)
    #4.11
    #[point1,point2].transpose.map do |p|
    #  t=(p[1]-p[0])
    #  t*t
    #end.sum
    
    #2.43
    dist = 0
    point1.each_index do |i|
      diff = point1[i]-point2[i]
      dist += diff*diff
    end
    dist
  end
  
  inline :C do |builder|
    
  end
end

#Just like group_by, except that results is just a grouped array
module Enumerable
  #def mygroup_by
  #  assoc = Hash.new
  #  res = []
  #  each do |element|
  #    key = yield(element)
  #    if assoc.has_key?(key)
  #      res[assoc[key]] << element
  #    else
  #      assoc[key] = res.size
  #      res << [element]
  #    end
  #  end
  #  res
  #end
  
  def mygroup_by
    assoc = Hash.new
    res = []
    each_index do |index|
      element = self[index]
      key = yield(element,index)
      if assoc.has_key?(key)
        res[assoc[key]] << element
      else
        assoc[key] = res.size
        res << [element]
      end
    end
    res
  end
end
