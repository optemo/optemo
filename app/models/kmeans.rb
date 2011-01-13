class Kmeans
require 'rubygems'
require 'inline'

inline :C do |builder|
  builder.c "
  #include <math.h> 
  static VALUE kmeans_c(VALUE _points_cont, VALUE _points_bin, VALUE _points_cat, _VALUE n, VALUE d_cont, VALUE d_bin, VALUE d_cat, VALUE dim_per_cat,...
   VALUE cluster_n,VALUE _factors, VALUE _weights, VALUE _inits){
    VALUE* points_cont_a = RARRAY_PTR(_points_cont);
    VALUE* points_bin_a = RARRAY_PTR(_points_bin);
    VALUE* points_cat_a = RARRAY_PTR(_points_cat);
    VALUE* weights_a = RARRAY_PTR(_weights);
    VALUE* factors_a = RARRAY_PTR(_factors);
    VALUE* inits_a = RARRAY_PTR(_inits);
    
    int nn = NUM2INT(n);
    int dd_cont = NUM2INT(d_cont);
    int dd_bin = NUM2INT(d_bin);
    int dd_cat = NUM2INT(d_cat);
    
    int k = NUM2INT(cluster_n);
    double DBL_MAX = 10000000.0;
    double t = 0.000000001;
    
    VALUE labels_and_reps = rb_ary_new2(nn+k);
    int i, j, h;
    double** data_cont = malloc(sizeof(double*)*nn);
    double** data_bin = malloc(sizeof(int**)*nn);
    double** data_cat = malloc(sizeof(int**)*nn);
    
    int* inits = malloc(sizeof(int)*k);
    double* utilities = (double*)calloc(nn, sizeof(double)); 
    int* newlabels = (int*)calloc(k, sizeof(int)); 
    int* newreps = (int*)calloc(k, sizeof(int)); 
    double* weights = malloc(sizeof(double)*dd_cont);
    int* reps = malloc(sizeof(int)*k);
    
    for (j=0; j<dd_cont; j++) weights[j] = NUM2DBL(weights_a[j]);
    for (i=0; i<k; i++) inits[i] = NUM2INT(inits_a[i]);  
    
        
    double* avgUtilities = (double*)calloc(k, sizeof(double)); 
    for (i=0; i<nn; i++) data_cont[i] = malloc(sizeof(double)*dd_cont);    
    for (i=0; i<nn; i++){
      for (j=0; j<dd_cont; j++) {   
         data_cont[i][j]= NUM2DBL(points_cont_a[i*dd_cont+j]);
         utilities[i] += weights[j]*NUM2DBL(factors_a[i*dd_cont+j]);  
      }
    }
       
 //kmeans initializations
   int *counts = (int*)calloc(k, sizeof(int)); /* size of each cluster */
   double *dif = (double*)calloc(k, sizeof(double)); 
   double old_error, error = DBL_MAX; /* sum of squared euclidean distance */
   double** means_1 = malloc(sizeof(double*)*k);
   double** means_2 = malloc(sizeof(double*)*k);
   for (i=0; i<k; i++) means_1[i]= malloc(sizeof(double)*(dd_cont+ dd_bin + dd_cat));
   for (i=0; i<k; i++) means_2[i]= malloc(sizeof(double)*(dd_cont+ dd_bin + dd_cat));
   int *labels = (int*)calloc(nn, sizeof(int));

   //////////////////////////////////////////////////////////////////////data standardization 
   ////////getting mean and var of the data
    double* dataMean = (double*)calloc(dd_cont, sizeof(double));
    double* dataVar = (double*)calloc(dd_cont, sizeof(double));
 	
 	  for (h = 0; h < nn; h++){ 
 	  	for (j = 0; j < dd_cont; j++) {
 	 	  	 dataMean[j] += data_cont[h][j]; 
 	 	  	 dataVar[j] += data_cont[h][j] * data_cont[h][j];
 	    }
 	   }   
 	  for (j = 0; j < dd_cont; j++) {
 	  	if (nn>0) {
 	  	  dataMean[j] = dataMean[j] / nn;
 	  	  dataVar[j] = sqrt(dataVar[j]/nn - (dataMean[j] * dataMean[j]));
 	  	}  
 	  }
   
     
     for (h = 0; h < nn; h++) {
     	for (j = 0; j < dd_cont; j++){
     	  if (dataVar[j] >0) data_cont[h][j] = (data_cont[h][j] - dataMean[j]) / dataVar[j];  	
   	  }
     }
   
   ///initializing the first means
    for(h=0; h<k;h++)
       for(j=0; j<dd_cont; j++) means_1[h][j] = data_cont[inits[h]][j];
   
   double z=0.0;
   double tmp_min = DBL_MAX;
   int tmp_ind=0;
    //////////////////////////////////////////////////////////////////////performing kmeans 
   
   do{
    
     //means_2= means_1
     for(h=0; h<k;h++)
       for(j=0; j<dd_cont; j++) means_2[h][j] = means_1[h][j];
   
     
     //finding the closest mean to assign the labels
     for (i=0; i<nn; i++){
        tmp_min = DBL_MAX;
       for (h=0; h<k; h++){
         dif[h] = 0.0;     
         for (j=0; j<dd_cont; j++) dif[h] += weights[j]*((data_cont[i][j]-means_1[h][j])*(data_cont[i][j]-means_1[h][j]));
         if (tmp_min>dif[h]){
           tmp_min = dif[h];
           tmp_ind = h;
         } 
       }
       labels[i] = tmp_ind;
     }
      
      
     //computing the new means
     for (h=0; h<k; h++)
       for (j=0; j<dd_cont; j++) {
         means_1[h][j] = 0.0;
         counts[h] = 0;
       }  
      
     for (i=0; i<nn; i++){
         h = labels[i];
         counts[h]++;
         for (j=0; j<dd_cont;j++) means_1[h][j] += data_cont[i][j];
     }     
     for (h=0; h<k; h++)
       for (j=0; j<dd_cont; j++) means_1[h][j]=means_1[h][j]/counts[h]; 
       
       
     //calculatig the difference between the old and the new means 
     z=0.0;
     for(h=0; h<k;h++)
       for(j=0; j<dd_cont; j++) z += (means_1[h][j]- means_2[h][j])*(means_1[h][j]- means_2[h][j]);  
   }while (z>t);
 
// //If it's all in one cluster, split them
// int all_one_flag=1;
// for(i=0; i<nn; i++) 
//   if (labels[i]>0) {
//     all_one_flag = 0;
//     break;
//   }  

// if (all_one_flag==1){ 
//   for(i=0; i<k; i++) labels[i] = i;
// }  
// 
   for (i=0; i<k; i++) reps[i] = -1;
   for (i=0; i<nn; i++){
     h = labels[i];
     if (utilities[reps[h]]<utilities[i]) reps[h]=i;
     avgUtilities[h] += utilities[i]; 
   }

   double minU = DBL_MAX;
   for (h=0; h<k; h++) {
     if (counts[h]>0) avgUtilities[h] = avgUtilities[h]/counts[h];
   }  
     
  //////////////////////////////////////////////////////////////////////sort based on utilties   
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
     labels[i] = newlabels[h];
     it=0;
     while (it<k-1 && ids[it]!=h){
       it++;
     }
     
     labels[i] = it;
     id_map[temp_labels[i]] = it;  
     //id_map[labels[i]] = it;
   }

 for (j=0; j<k; j++) temp_reps[j] = reps[j];
   for (j=0;j<k; j++){
     reps[id_map[j]] = temp_reps[j];
 }

////storing the labels in the ruby array
  for (j=0; j<nn; j++) rb_ary_store(labels_and_reps, j, INT2NUM(labels[j]));
  for (j=0; j<k; j++) rb_ary_store(labels_and_reps, nn+j, INT2NUM(reps[j]));
  return labels_and_reps;
  }
  "
end



# C kmeans function   
def self.compute(number_clusters,p_ids)

  s = p_ids.size 
  factors =[]
  Session.current.continuous["cluster"].each do |f| 
    f_specs = ContSpec.by_feat(f+"_factor")
    raise ValidationError, "There are no #{f}_factors for #{Session.current.product_type}" unless f_specs
    factors << f_specs
  end
  ft = factors.transpose
  dim_cont = Session.current.continuous["cluster"].size
  dim_bin = Session.current.binary["cluster"].size
  dim_cat = Session.current.categorical["cluster"].size
  weights = self.set_weights(dim_cont, dim_bin, dim_cat)
  
  # don't need to cluster if number of products is less than clusters

  if (s<number_clusters)
    utilitylist = weighted_ft(ft, weights).map{|f| f. inject(:+)}
    #if utilities are the same
    utilitylist.each_with_index{|u, i| utilitylist[i]=u+(0.0000001*i)} if utilitylist.uniq.size<s
    util_tmp = utilitylist.sort{|x,y| y <=> x }    
    ordered_list = util_tmp.map{|u| utilitylist.index(u)}
    return ordered_list + ordered_list
  end  
  
  begin
    st = Product.specs(p_ids)
    cont_specs = st[0...dim_cont].transpose
    bin_specs = st[dim_cont...dim_cont+dim_bin].transpose
    cat_specs = st[dim_cont+dim_bin...st.size].transpose
    debugger
    dim_per_cat = cat_specs.first.map{|f| f.size}
    
    raise ValidationError, "No specs available" if cont_specs.nil?
    raise ValidationError, "Factors not available for the same number of features as specs" unless ft.size == cont_specs.size
    raise ValidationError, "Number of factors is not equal to the dimension of continuous specs" unless ft.first.size == cont_specs.first.size 
    raise ValidationError, "Number of weights is not equal to the total dimension of specs" unless weights.size == dim_cont+dim_bin+ dim_cat
    
    # inistial seeds for clustering  ### just based on contiuous features
    inits = self.init(number_clusters, cont_specs, weights[0...dim_cont]) 

    $k = Kmeans.new unless $k
    #static VALUE kmeans_c(VALUE _points_cont, VALUE _points_bin, VALUE _points_cat, _VALUE n, VALUE d_cont, VALUE d_bin, VALUE d_cat, VALUE dim_per_cat,...
    #  VALUE cluster_n,VALUE _factors, VALUE _weights, VALUE _inits){
    $k.kmeans_c(cont_specs.flatten, bin_specs.flatten, cat_specs.flatten, cont_specs.size, dim_cont,  dim_bin.size, dim_cat.size, dim_per_cat,number_clusters, ft.flatten, weights, inits.flatten)  
     
  rescue ValidationError => e
    puts "Falling back to ruby kmeans: #{e.message}"
    debugger
    Kmeans.ruby(number_clusters, specs)
  end
end


def self.init(number_clusters, specs, weights)
  centers = [specs[(specs.size-1)/2]]
  for j in (0...number_clusters-1)
      actual_dists = centers.map{|c| specs.map{|s| self.distance(c,s, weights)}}.transpose.map{|j| j.min}
      centers << specs[actual_dists.index(actual_dists.max)]
  end  
  centers.map{|c| specs.index(c)} 
end

def self.set_weights(dim_cont, dim_bin, dim_cat)
  dim = dim_cont+dim_bin+dim_cat
  if Session.current.search.sortby=='Price' # price is selected as prefered order
    weights = [0.05/(dim-1)]*dim  
    weights[Session.current.continuous["cluster"].index('price')] = 0.95    
  else
    weights = [1.0/dim]*dim
  end
  weights                         
end


# regular kmeans function     ## ruby function does not sort by utility and don't pick the highest utility as the rep
def self.ruby(number_clusters, specs, weights, inits)
  weights = [1]*specs.first.size if weights.nil?
  thresh = 0.000001
  #mean_1 = self.seed(number_clusters, specs)
  mean_1 = inits.each{|i| specs[i]}
  mean_2 =[]
  labels = []
  dif = []
  begin
   mean_2 = mean_1 
   specs.each_index do |i| 
     mean_1.each_index do |c|
       dif[c] = self.distance(specs[i], mean_1[c], weights)
     end
     labels[i] = dif.index(dif.min)
   end 
   mean_1= self.means(number_clusters, specs, labels)
   z=0.0;
   mean_1.each_index{|c| z+=self.distance(mean_1[c], mean_2[c], weights)}
  end while z > thresh
  reps = [];
  (0...s).to_a.each{|i| reps<< labels.index(i)}
  labels + reps   
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
def self.distance(point1, point2, weights)
  dist = 0
  point1.each_index do |i|
    diff = 0
    if point1[i].kind_of?(Array)
       diff = weights[i] unless points[1].eql?(points[2])
    else
       diff = weights[i]*(point1[i]-point2[i])
    end  
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

  def self.weighted_ft(ft, weights)
    weighted_ft=[]
    for i in (0...ft.size)
      weighted_ft_i = []
      ft[i].each_with_index{|f,j| weighted_ft_i << weights[j]*f}
      weighted_ft << weighted_ft_i
    end
    return weighted_ft
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