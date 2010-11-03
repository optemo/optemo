class Kmeans
require 'inline'

inline :C do |builder|
  builder.c "
  #include <math.h> 
  static VALUE kmeans_c(VALUE _points, VALUE n, VALUE d, VALUE cluster_n){
    VALUE* points_a = RARRAY_PTR(_points);
    int nn = NUM2INT(n);
    int dd = NUM2INT(d);
    int k = NUM2INT(cluster_n);
    double DBL_MAX = 10000000.0;
    double t = 0.0001;
    
    VALUE labels_r = rb_ary_new2(nn);
    int i, j, h;
    double** data = malloc(sizeof(double*)*nn);

    for (i=0; i<nn; i++) data[i] = malloc(sizeof(double)*dd);    
    for (i=0; i<nn; i++){
      for (j=0; j<dd; j++) {   
         data[i][j]= NUM2DBL(points_a[i*dd+j]);
      }
    }
  
  ////////getting mean and var of the data
    double* dataMean = malloc(sizeof(double)*dd);
    double* dataVar = malloc(sizeof(double)*dd); 
	  for (j = 0; j < dd; j++) {
	 	 dataMean[j]=0; 
	 	 dataVar[j]= 0;
	  }
	  for (h = 0; h < nn; h++){ 
	  	for (j = 0; j < dd; j++) {
	 	  	dataMean[j] += data[h][j]; 
	 		 dataVar[j] += data[h][j] * data[h][j];
	      }
	   }   
	  for (j = 0; j < dd; j++) {
	  	dataMean[j] = dataMean[j] / nn;
	  	dataVar[j] = sqrt(dataVar[j]/nn - dataMean[j] * dataMean[j]);
	  }
  
  ///////data standardization 
    for (h = 0; h < nn; h++) {
    	for (j = 0; j < dd; j++)
    		data[h][j] = (data[h][j] - dataMean[j]) / dataVar[j];
    	//for (int j = 0; j < bool_feats; j++)
    	//	dataN[h][dd + j] = data[h][con_feats + j];	
    }
  
  
  ///////Kmeans data      
    int *counts = (int*)calloc(k, sizeof(int)); //(int*)calloc(k, sizeof(int)); /* size of each cluster */
    double old_error, error = DBL_MAX; /* sum of squared euclidean distance */
    double** centroids = malloc(sizeof(double*)*k);
    for (i=0; i<k; i++) centroids[i]= malloc(sizeof(double)*dd);
    double **c = (double**)calloc(k, sizeof(double*));
    double **c1 = (double**)calloc(k, sizeof(double*)); /* temp centroids */
    int *labels = (int*)calloc(nn, sizeof(int)); 
    
        
  for (h = i = 0; i < k; h += nn / k, i++) {
     c1[i] = (double*)calloc(dd, sizeof(double));
     c[i] = (double*)calloc(dd, sizeof(double));
     /* pick k points as initial centroids */
     for (j = dd; j-- > 0; c[i][j] = data[h][j]);
  }
  
  /****
  ** main loop */
  
  do {
     /* save error from last step */
     old_error = error, error = 0;
  
     /* clear old counts and temp centroids */
     for (i = 0; i < k; counts[i++] = 0) {
        for (j = 0; j < dd; c1[i][j++] = 0);
     }
  
     for (h = 0; h < nn; h++) {
        /* identify the closest cluster */
        double min_distance = DBL_MAX;
        for (i = 0; i < k; i++) {
           double distance = 0;
           for (j = dd; j-- > 0; distance += (data[h][j] - c[i][j]) * (data[h][j] - c[i][j])) ;
           if (distance < min_distance) {
              labels[h] = i;
              min_distance = distance;
           }
        }
        /* update size and temp centroid of the destination cluster */
        for (j = dd; j-- > 0; c1[labels[h]][j] += data[h][j]);
        counts[labels[h]]++;
        /* update standard error */
        error += min_distance;
     }
  
     for (i = 0; i < k; i++) { /* update all centroids */
        for (j = 0; j < dd; j++) {
           c[i][j] = counts[i] ? c1[i][j] / counts[i] : c1[i][j];
        }
     }
  
  } while (((error - old_error)*(error - old_error)) > t);
  
  for (j=0; j<nn; j++){
      rb_ary_store(labels_r, j, INT2NUM(labels[j]));
  }
  return labels_r;
  }
  "
end

# C kmeans function   
def self.compute(number_clusters,p_ids, weights = nil)
  begin
    specs = Product.specs(p_ids)
    $k = Kmeans.new unless $k
    $k.kmeans_c(specs.flatten, specs.size, specs.first.size, number_clusters)
  rescue
    puts "Falling back to ruby kmeans"
    debugger
    Kmeans.ruby(number_clusters, specs)
  end
end

# regular kmeans function   
def self.ruby(number_clusters, specs, weights = nil)
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
  s = points.size.to_f
  points.transpose.map{|p| p.inject(:+)/s}
end

# Finding the means of all clusters
# Group the specs based on their labels and within each group, find their mean
def self.means(number_clusters, specs, labels)
  specs.mygroup_by{|e,i|labels[i]}.map{|s|self.mean(s)}
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

#### New functions
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

end

#Just like group_by, except that results is just a grouped array
module Enumerable
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