class Kmeans
require 'rubygems'
require 'inline'

inline :C do |builder|
  builder.c "
  #include <math.h> 
  static VALUE kmeans_c(VALUE _points, VALUE n, VALUE d, VALUE cluster_n, VALUE _utilities){
    VALUE* points_a = RARRAY_PTR(_points);
    VALUE* utilities_a = RARRAY_PTR(_utilities);
    int nn = NUM2INT(n);
    int dd = NUM2INT(d);
    int k = NUM2INT(cluster_n);
    double DBL_MAX = 10000000.0;
    double t = 0.000000001;
    
    VALUE labels_r = rb_ary_new2(nn);
    int i, j, h;
    double** data = malloc(sizeof(double*)*nn);
    double* utilities = malloc(sizeof(double)*nn); 
    double* avgUtilities = (double*)calloc(k, sizeof(double)); 
    for (i=0; i<nn; i++) data[i] = malloc(sizeof(double)*dd);    
    for (i=0; i<nn; i++){
      for (j=0; j<dd; j++) {   
         data[i][j]= NUM2DBL(points_a[i*dd+j]);
      }
    utilities[i] = NUM2DBL(utilities_a[i]);  
    }
  
  //kmeans initializations
    int *counts = (int*)calloc(k, sizeof(int)); /* size of each cluster */
    double *dif = (double*)calloc(k, sizeof(double)); 
    double old_error, error = DBL_MAX; /* sum of squared euclidean distance */
    double** means_1 = malloc(sizeof(double*)*k);
    double** means_2 = malloc(sizeof(double*)*k);
    for (i=0; i<k; i++) means_1[i]= malloc(sizeof(double)*dd);
    for (i=0; i<k; i++) means_2[i]= malloc(sizeof(double)*dd);
    int *labels = (int*)calloc(nn, sizeof(int));

  
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
      	for (j = 0; j < dd; j++){
      		data[h][j] = (data[h][j] - dataMean[j]) / dataVar[j];
      	//for (int j = 0; j < bool_feats; j++)
      	//	dataN[h][dd + j] = data[h][con_feats + j];	
    	  }
      }
    
    ///initializing the first means
     for(h=0; h<k;h++)
        for(j=0; j<dd; j++) means_1[h][j] = data[h][j];
    
    double z=0.0;
    double tmp_min = DBL_MAX;
    int tmp_ind=0;
    ///////performing kmeans 
    
    do{
     
      //means_2= means_1
      for(h=0; h<k;h++)
        for(j=0; j<dd; j++) means_2[h][j] = means_1[h][j];
    
      
      //finding the closest mean to assign the labels
      for (i=0; i<nn; i++){
         tmp_min = DBL_MAX;
        for (h=0; h<k; h++){
          dif[h] = 0.0;     
          for (j=0; j<dd; j++) dif[h] += (data[i][j]-means_1[h][j])*(data[i][j]-means_1[h][j]);
          if (tmp_min>dif[h]){
            tmp_min = dif[h];
            tmp_ind = h;
          } 
        }
        labels[i] = tmp_ind;
      }
      
      
      //computing the new means
      for (h=0; h<k; h++)
        for (j=0; j<dd; j++) {
          means_1[h][j] = 0.0;
          counts[h] = 0;
        }  
       
      for (i=0; i<nn; i++){
          h = labels[i];
          counts[h]++;
          for (j=0; j<dd;j++) means_1[h][j] += data[i][j];
      }     
      for (h=0; h<k; h++)
        for (j=0; j<dd; j++) means_1[h][j]=means_1[h][j]/counts[h]; 
       
       
      //calculatig the difference between the old and the new means 
      z=0.0;
      for(h=0; h<k;h++)
        for(j=0; j<dd; j++) z += (means_1[h][j]- means_2[h][j])*(means_1[h][j]- means_2[h][j]);  
    }while (z>t);
  
  //If it's all in one cluster, split them
  int all_one_flag=1;
  for(i=0; i<nn; i++) 
    if (labels[i]>0) {
      all_one_flag = 0;
      break;
    }  

  if (all_one_flag==1){ 
    for(i=0; i<k; i++) labels[i] = i;
  }  
  
  
    for (i=0; i<nn; i++){
      h = labels[i];
      avgUtilities[h] += utilities[i]; 
    }
 
    double minU = DBL_MAX;
    for (h=0; h<k; h++) {
      if (counts[h]==0) avgUtilities[h] = avgUtilities[h];
      else  avgUtilities[h] = avgUtilities[h]/counts[h];
    }  
      
   //sort based on utilties   
     int idKey;
     double key;	 
     int* ids = malloc(sizeof(int)*k);
     double* x = (double*)calloc(k, sizeof(double));
     for (j=0; j<k; j++) x[j] = avgUtilities[j];
     
  for (h=0; h<k; h++) ids[h]=h;
  for(j=1;j<k;j++){
     key=x[j];
  	   idKey = ids[j];	
        i=j-1;

        while(x[i]<key && i>=0)
        {
            x[i+1]=x[i];
   		     ids[i+1] = ids[i];	
            i--;
        }
        x[i+1] = key;
     	ids[i+1] = idKey;
    }
  //changing the label assignement based on the utilitites.    
    for (i=0; i<nn; i++) {
      h =  labels[i];
      labels[i] = ids[h];  
    }

 //storing the labels in the ruby array
  for (j=0; j<nn; j++) rb_ary_store(labels_r, j, INT2NUM(labels[j]));
  
  return labels_r;
  }
  "
end



# C kmeans function   
def self.compute(number_clusters,p_ids, weights = nil)

  s = p_ids.size 
  # don't need to cluster if number of products is less than clusters
  return (0...s).collect{|x| x} if (s<number_clusters)

  begin
    specs = Product.specs(p_ids)
    utility_list = ContSpec.by_feat("utility")
    raise ValidationError if utility_list.nil?
    $k = Kmeans.new unless $k
    $k.kmeans_c(specs.flatten, specs.size, specs.first.size, number_clusters, utility_list)
  rescue ValidationError
    puts "Falling back to ruby kmeans"
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
    #debugger
    var.each_index{|i| var[i]=Math.sqrt((var[i]/count) - (mean_all[i]**2))}
    var_all
  end

end
class ValidationError < ArgumentError; end
#Just like group_by, except that results is just a grouped array
module Enumerable
#def mygroup_by
#  assoc = Hash.new
#  res = []
#  each_index do |index|
#    element = self[index]
#    key = yield(element,index)
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
  res = Array.new(9)
  each_index do |index|
    element = self[index]
    key = yield(element,index)
    if res[key].nil? 
      res[key] =[element] 
    else  
      res[key]<< element
    end  
  end
  res.compact
end
end