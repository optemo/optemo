  class  Kmeans
  require 'rubygems'
  require 'inline'

  inline :C do |builder|
    builder.c "
    #include <math.h> 
    static VALUE kmeans_c(VALUE _points, _VALUE n, VALUE d, VALUE cluster_n,VALUE _weights, VALUE _utilities, VALUE _inits){

     VALUE* points_a = RARRAY_PTR(_points);
     VALUE* weights_a = RARRAY_PTR(_weights);
     VALUE* utilities_a = RARRAY_PTR(_utilities);
     VALUE* inits_a = RARRAY_PTR(_inits);
     int nn = NUM2INT(n);
     int dd = NUM2INT(d);
     int k = NUM2INT(cluster_n);
     double DBL_MAX = 10000000.0;
     double tresh = 0.0001;
     double z=0.0;
     double z_temp = 0.0;
     int max_ind=0;
     double tmp_min = DBL_MAX;
     int tmp_ind=0;
     int not_eq_flag = 0;
     VALUE labels_and_reps = rb_ary_new2(nn);
     int i, j, h,t;

    int* inits = malloc(sizeof(int)*k);
    for (i=0; i<k; i++) inits[i] = NUM2INT(inits_a[i]);
    double** data = malloc(sizeof(double*)*nn);
    double* utilities = malloc(sizeof(double)*nn);
    double* avgUtilities = malloc(sizeof(double)*k);

    for (i=0; i<nn; i++){
      data[i] = malloc(sizeof(double)*dd);
      for (j=0; j<dd; j++) data[i][j] = NUM2DBL(points_a[dd*i+j]);
      utilities[i] = NUM2DBL(utilities_a[i]);   
    } 


 //kmeans initializations
   double *counts = (int*)calloc(k, sizeof(int)); /* size of each cluster */
   double *dif = (double*)calloc(k, sizeof(double)); 
   double old_error, error = 1000000000.0; /* sum of squared euclidean distance */
   double** means_1 = malloc(sizeof(double*)*k);
   double** means_2 = malloc(sizeof(double*)*k);

   for (i=0; i<k; i++){
     means_1[i]= malloc(sizeof(double)*(dd));
     means_2[i]= malloc(sizeof(double)*(dd)); 
   }    

    int* labels = malloc(sizeof(int)*nn);//(int*)calloc(nn, sizeof(int));
    int *reps = (int*)calloc(k, sizeof(int));
    ///initializing the first means
   for(h=0; h<k;h++){
      for(j=0; j<dd; j++) means_1[h][j] = data[inits[h]][j];
    }        

     //////////////////////////////////////////////////////////////////////performing kmeans 

    do{
   //means_2= means_1
   for(h=0; h<k;h++){
     for(j=0; j<dd; j++) means_2[h][j] = means_1[h][j];
   }
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
      for (h=0; h<k; h++){
        counts[h] = 0;
        for (j=0; j<dd; j++) means_1[h][j] = 0.0;
       } 

      for (i=0; i<nn; i++){
          h = labels[i];
          counts[h]++;
          for (j=0; j<dd; j++) means_1[h][j] += data[i][j];
      }     
      for (h=0; h<k; h++) for (j=0; j<dd; j++) means_1[h][j]=means_1[h][j]/counts[h]; 

      //calculatig the difference between the old and the new means 
      z=0.0;
      for(h=0; h<k;h++){
        z_temp=0.0;
        for(j=0; j<dd; j++) z_temp += (means_1[h][j]- means_2[h][j]);
        z+=z_temp*z_temp; 
       }   
    }while (z>tresh);

 
    double minU = DBL_MAX;
    for (h=0; h<k; h++) {
      if (counts[h]>0) avgUtilities[h] = avgUtilities[h]/counts[h];  
    } 
    for (h=0; h<k; h++){
        for (i=0; i<nn; i++){
          if (labels[i]==h){
            reps[h] = i;
            break;
          }
        }
    }
    
    for (i=0; i<nn; i++){
      h = labels[i];
      if (utilities[i] > utilities[reps[h]]) reps[h] = i;
    }

  //////////////////////////////////////////////////////////////////////sort based on utilities   
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
   int it;
   int* id_map = calloc(k,sizeof(int));
   int* temp_reps = calloc(k,sizeof(int));
   int* temp_labels = calloc(nn,sizeof(int));
   for (i=0; i<nn; i++)temp_labels[i] = labels[i];
 /////////////////////////////////////////////////////////////////////////changing the label assignment based on avg utilities.    
  for (i=0; i<nn; i++) {
    h =  labels[i];
    it=0;
    while (it<k-1 && ids[it]!=h){
      it++;
    }

    labels[i] = it;
    id_map[temp_labels[i]] = it;  
  }

for (j=0; j<k; j++) {
  temp_reps[j] = reps[j];
}  
for (j=0;j<k; j++){
   reps[id_map[j]] = temp_reps[j];
}

  ///storing the labels in the ruby array
   for (j=0; j<nn; j++) rb_ary_store(labels_and_reps, j, INT2NUM(labels[j]));
   for (j=0; j<k; j++) rb_ary_store(labels_and_reps, nn+j, INT2NUM(reps[j]));
   return labels_and_reps;
    }
    "
  end

 
 def self.compute(number_clusters,p_ids)
 
  dim_cont = Session.continuous["cluster"].size
  dim_bin = Session.binary["cluster"].size
  dim_cat = Session.categorical["cluster"].size
  cluster_weights = self.set_cluster_weights(dim_cont, 0, 0)
  utility_weights = self.set_utility_weights(dim_cont, 0, 0)
  s = p_ids.size
  
  if (s<number_clusters)
    ft = self.factorized_cont_data
    if ft.empty?
      utilitylist = [1]*s
    else 
      brand_factors = self.factorized_brand
      utilitylist = ContSpec.by_feat("utility")#weighted_ft(ft.each_with_index{|f, i| f<<brand_factors[i]}, utility_weights).map{|f| f. inject(:+)}
    end  
    #if utilities are the same
    utilitylist.each_with_index{|u, i| utilitylist[i]=u+(0.0000001*i)} if utilitylist.uniq.size<s
    util_tmp = utilitylist.sort{|x,y| y <=> x }    
    ordered_list = utilitylist.map{|u| util_tmp.index(u)}
    return ordered_list + ordered_list
  end
 
    performance_weight = 2
    #weights = weights << performance_weight
    weight_dim = dim_cont #+dim_bin+dim_cat+1
    # dimension of each category - for example how many different brands 
   # dim_per_cat = cat_specs.first.map{|f| f.size}
   
    # inistial seeds for clustering  ### just based on contiuous features
    ft = self.factorized_cont_data
    inits = self.init(number_clusters, ft, cluster_weights[0...dim_cont])
    
    #static VALUE kmeans_c(VALUE _points, _VALUE n, VALUE d, VALUE cluster_n,VALUE _weights, VALUE _utilities, VALUE _inits)
    utilities = ContSpec.by_feat("utility")
    $k = Kmeans.new unless $k
    labels = $k.kmeans_c(ft.flatten, ft.size, ft.first.size, number_clusters, [0.33,0.33,0.33], utilities, inits)
    #Kmeans.ruby(number_clusters, cluster_weights[0...dim_cont], utility_weights, inits)
    labels
end


def self.init(number_clusters, specs, weights)
  centers = [specs[(specs.size-1)/2]]
  for j in (0...number_clusters-1)
      actual_dists = centers.map{|c| specs.map{|s| self.distance(c,s, weights)}}.transpose.map{|j| j.min}
      centers << specs[actual_dists.index(actual_dists.max)]
  end  
  centers.map{|c| specs.index(c)} 
end

def self.set_cluster_weights(dim_cont, dim_bin, dim_cat)
  weights = []
  if Session.search.sortby.nil? || Session.search.sortby == "relevance"
    Session.continuous["cluster"].each{|f| weights << Session.cluster_weight[f]}
    weights_sum = weights.sum
    weights.map{|w| w/weights.sum.to_f}
  else
    weights = [0/dim_cont]*dim_cont 
    weights[Session.continuous["cluster"].index(Session.search.sortby)] = 1
  end
  weights
end


def self.set_utility_weights(dim_cont, dim_bin, dim_cat)
  weights = []
  if Session.search.sortby.nil? || Session.search.sortby == "relevance"
    Session.continuous["cluster"].each{|f| weights << Session.utility_weight[f] if Session.utility_weight[f]}
    weights_sum = weights.sum
    weights.map{|w| w/weights.sum.to_f}
    weights << 10
  else
    weights = [0.0/dim_cont]*dim_cont 
    weights[Session.continuous["cluster"].index(Session.search.sortby)] = 0.99
    weights << 0.01
  end
  weights  
end

# regular kmeans function     
## ruby function only cluster based on continuous data 
## ruby function does not sort by utility and don't pick the highest utility as the rep
def self.ruby(number_clusters, cluster_weights, utility_weights, inits)
  thresh = 0.000001
  standard_specs = self.factorized_cont_data#self.standardize_cont_data(specs)
  brand_factors = self.factorized_brand
  mean_1 = inits.map{|i| standard_specs[i]}
  mean_2 =[]
  labels = []
  dif = []
  begin 
   mean_2 = mean_1 
   standard_specs.each_index do |i| 
     mean_1.each_index do |c|
       dif[c] = self.distance(standard_specs[i], mean_1[c], cluster_weights)
     end
     labels[i] = dif.index(dif.min)
   end 
   mean_1= self.means(number_clusters, standard_specs, labels)
   z=0.0;
   
   mean_1.each_index do |c|
      mean_1[c] = [0]*standard_specs.first.size if mean_1[c].nil?
      mean_2[c] = [0]*standard_specs.first.size if mean_2[c].nil?
      debugger if mean_2[c].nil?
      z+=self.distance(mean_1[c], mean_2[c], cluster_weights)
   end    
  end while z > thresh
   # postprocessing if one cluster is collapsed
   if labels.uniq.size <labels.max+1
     labels = labels.map{|l| labels.uniq.index(l)}
   end
   # split if there is only one cluster
   if labels.uniq.size ==1
     (0...number_clusters-1).to_a.each{|i| labels[i] = i}
     (number_clusters-1...labels.size).to_a.each{|i| labels[i] = number_clusters -1}
   end
  reps = [];
  #utility ordering
  utilitylist = ContSpec.by_feat("utility")#weighted_ft(standard_specs.each_with_index{|f, i| f<<brand_factors[i]}, utility_weights).map{|f| f. inject(:+)}  
  utilitylist.each_with_index{|u, i| utilitylist[i]=u+(0.0000001*i)} if utilitylist.uniq.size<number_clusters
  grouped_utilities = group_by_labels(utilitylist, labels).map{|g| g.inject(:+)/g.length}
  sorted_group_utilities = grouped_utilities.sort{|x,y| y<=>x}
  sorted_labels = []
  labels.each_index{|i| sorted_labels << sorted_group_utilities.index(grouped_utilities[labels[i]])}
  (0...number_clusters).to_a.each{|i| reps<< sorted_labels.index(i)}
  sorted_labels + reps   
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
  #debugger if points.flatten.include
  points.transpose.map{|p| p.inject(:+)/s}
end

# Finding the means of all clusters
# Group the specs based on their labels and within each group, find their mean
def self.means(number_clusters, specs, labels)
  specs.mygroup_by{|e,i|labels[i]}.map{|s|self.mean(s)}
end

#Euclidian distance function
def self.distance(point1, point2, weights)
  dist = dim = 0.0
  point1.each_index do |i|
      unless (point1[i].nil? || point2[i].nil?)
        diff = weights[i]*(point1[i]-point2[i]) 
        dim = dim + 1
        dist += diff*diff
      end 
  end
  dist/dim
end

#### New functions
# converts categorical spec values to binary arrays
  def self.standardize_cat_data(specs)
    specs = specs.transpose
    #cont_size=3
    #cats = ["brand"]
    cont_size = Session.continous["filter"].size
    Session.categorical["filter"].each_index do |i|
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
  
  def self.factorized_cont_data
   Session.continuous["cluster"].map{|f| ContSpec.by_feat(f+"_factor")}.transpose
  end  
  def self.factorized_brand #(specs)
    ContSpec.by_feat("brand_factor")
  end
  #   
  def self.standardize_cont_data(specs)
    mean_all = mean(specs)
    var_all = self.get_var(specs, mean_all)
    specs.each{|p| p.each_with_index{|v, i| p[i]=(v-mean_all[i])/var_all[i]}}
  end
  
  # finds the standard deviation for every dimension(feature)
  def self.get_var(specs, mean_all)
    count = specs.size
    var = []
    specs.transpose.each{|p| var << p.each_index{|i| i*i}.inject(:+)}
    var.each_index.each do |i| 
      var[i]=Math.sqrt(((var[i]/count) - (mean_all[i]**2)).abs)
    end  
    var
  end
  
  def self.extendedCluster(num)
    all_ids = SearchProduct.find_all_by_search_id(Product.initial).map(&:product_id)
    curr_ids = Session.search.products
    other_ids = all_ids - curr_ids
    curr_specs= self.factorized_cont_data
    all_specs = all_ids.map{|id| Session.continuous["cluster"].map{|f| ContSpec.cache_all(id)[f+"_factor"]}}
    other_specs =  []
    all_specs.each_with_index{|s,i| other_specs << all_specs[i] if other_ids.include?(all_ids[i]) }
    better_specs = []
    better_ids = []
    better_specs = []
    min_utility = ContSpec.cachemany(curr_ids, "utility").min
    other_specs.each_with_index do |s, i|
      if !ContSpec.cachemany([other_ids[i]], "utility").first.nil? && ContSpec.cachemany([other_ids[i]], "utility").first>min_utility
        better_ids << other_ids[i]
        better_specs <<  s
      end  
    end  
    dists = []
    dim = all_specs.first.size
    better_specs.each_with_index do |s2, ind| 
      dists<< curr_specs.map{|s1| self.distance(s1,s2, [1.0/dim]*dim)}.inject(:+)
    end             
    better_products_hash = Hash[better_ids.zip(dists)]
    better_products_hash.sort{|a,b| a[1] <=> b[1]}[0...num].map{|k, v| k} # num close products
  end
  
end
def group_by_labels(product_ids, cluster_ids)
  product_ids.mygroup_by{|e,i|cluster_ids[i]}
end

class ValidationError < ArgumentError; end
#Just like group_by, except that results is just a grouped array
module Enumerable

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