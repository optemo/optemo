class  Kmeans
  require 'rubygems'
  require 'inline'
  
  inline :C do |builder|
    builder.c "
    #include <math.h> 
    static VALUE kmeans_c(VALUE _points, _VALUE n, VALUE d, VALUE cluster_n,VALUE _weights, VALUE _utilities_rep, VALUE _utilities_gorder, VALUE _inits){
  
     VALUE* points_a = RARRAY_PTR(_points);
     VALUE* weights_a = RARRAY_PTR(_weights);
     VALUE* utilities_rep_a = RARRAY_PTR(_utilities_rep);
     VALUE* utilities_gorder_a = RARRAY_PTR(_utilities_gorder);
     VALUE* inits_a = RARRAY_PTR(_inits);
     int nn = NUM2INT(n);
     int dd = NUM2INT(d);
     int k = NUM2INT(cluster_n);
     double DBL_MAX = 10000000.0;
     double tresh = 0.000001;
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
    double* weights = (double*)calloc(dd, sizeof(double));
    double* utilities_rep = malloc(sizeof(double)*nn);
    double* utilities_gorder = malloc(sizeof(double)*nn);
    double* avgUtilities = (double*)calloc(k, sizeof(double)); 
  
    for (j=0; j<dd; j++) weights[j] = NUM2DBL(weights_a[j]);
    for (i=0; i<nn; i++){
      data[i] = malloc(sizeof(double)*dd);
      for (j=0; j<dd; j++) data[i][j] = NUM2DBL(points_a[dd*i+j]);
      utilities_rep[i] = NUM2DBL(utilities_rep_a[i]);
      utilities_gorder[i] = NUM2DBL(utilities_gorder_a[i]);     
    } 
  
  
  //kmeans initializations
   int *counts = malloc(sizeof(int)*k); /* size of each cluster */
   for (h=0; h<k;h++) counts[h] = 0;
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
    int tt = 0;
    do{
    tt ++;  
   //means_2= means_1
   for(h=0; h<k;h++){
     for(j=0; j<dd; j++) means_2[h][j] = means_1[h][j];
   }
   //finding the closest mean to assign the labels
   for (i=0; i<nn; i++){
      tmp_min = DBL_MAX;
     for (h=0; h<k; h++){
       dif[h] = 0.0;     
       for (j=0; j<dd; j++) {
         if (data[i][j]>0.0) dif[h] += weights[j]*(data[i][j]-means_1[h][j])*(data[i][j]-means_1[h][j]);
       }
       if (tmp_min>=dif[h]){
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
          if (h>=0 && h<k){
       	   counts[h]++;
       	   for (j=0; j<dd; j++) means_1[h][j] += data[i][j];
      	 }	
  }     
      for (h=0; h<k; h++){ 
  for (j=0; j<dd; j++) {
  	if (counts[h] == 0){
  		means_1[h][j]=0.0;
  	}else{
  		means_1[h][j] = means_1[h][j]/counts[h]; 
  	}
           }
      }
      //calculatig the difference between the old and the new means 
      z=0.0;
      for(h=0; h<k;h++){
        z_temp=0.0;
        for(j=0; j<dd; j++) z_temp += weights[j]*(means_1[h][j]- means_2[h][j]);
        z+=z_temp*z_temp; 
    }   
    }while (z>tresh && tt<150);
    for (i=0; i<nn; i++){
      h = labels[i];
      avgUtilities[h] += utilities_gorder[i];  
   }
    
   for (h=0; h<k; h++) {
     if (counts[h]>0) avgUtilities[h] = avgUtilities[h]/counts[h];  
   }   
  
  ////////////////////////////////////////////////////////////////////////sort based on utilities   
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
  int* sorted_labels = (int*)calloc(nn, sizeof(int));
  //int* sorted_reps = (int*)calloc(k, sizeof(int));
   
   for (j=0; j<k; j++){
     for (i=0; i<nn; i++)
       if (labels[i]==ids[j]) sorted_labels[i]=j;                   
   }
   
  ///storing the labels in the ruby array
   for (j=0; j<nn; j++) rb_ary_store(labels_and_reps, j, INT2NUM(sorted_labels[j]));
   return labels_and_reps;
    }
    "
  end
  
  
  def self.compute(number_clusters,products)
      cluster_weights = self.set_cluster_weights(Session.features["cluster"])
      s = products.size
      if (s<=number_clusters)
          utilitylist = Kmeans.utility(products, "gorder")
          #if utilities are the same
          utilitylist.each_with_index{|u, i| utilitylist[i]=u+(0.0000001*i)} if utilitylist.uniq.size<s
          util_tmp = utilitylist.sort{|x,y| y <=> x }    
          ordered_list = util_tmp.map{|u| utilitylist.index(u)}
          return ordered_list.map{|i| products[i]}
      end
      # initial seeds for clustering  ### just based on contiuous features
      inits = self.init(number_clusters, products, cluster_weights)
      standard_specs = self.factorize_cont_data(products)
      utilities_rep = Kmeans.utility(products, "rep")
      utilities_gorder  = Kmeans.utility(products, "gorder")
      utilities_gorder.each_with_index{|u, i| utilities_gorder[i]=u+(0.0000001*i)} if utilities_gorder.uniq.size<number_clusters
      begin
        raise ValidationError, "specs is nil or empty" if standard_specs.nil? || standard_specs.empty?
        raise ValidationError, "cluster_weights is nil or empty" if cluster_weights.nil? || cluster_weights.empty?
        raise ValidationErrot, "utilities_gorder is nil or empty" if utilities_gorder.nil? || utilities_gorder.empty?
        raise ValidationError, "utilities_rep is nil or empty" if utilities_rep.nil? || utilities_rep.empty?
        raise ValidationError, "inits is nil or empty" if inits.nil? || inits.empty?
          
        labels = $k.kmeans_c(standard_specs.flatten.map{|s| s.nil? ? 0.0 : s}, standard_specs.size , standard_specs.first.size, number_clusters, cluster_weights, utilities_rep, utilities_gorder, inits)
        $k = Kmeans.new unless $k
      
      rescue ValidationError  
        labels = self.ruby(number_clusters, cluster_weights, inits, products) #
        debugger
      end  
      
      sorted_products=[]
      until labels.empty?
        p_ins = []
        ([labels]*number_clusters).each_with_index{|l, i| p_ins << l.index(i) if l.index(i)}
        p_ins.map do |i| 
            sorted_products << products[i]
            labels[i] = nil; products[i] = nil
        end
        labels.compact!; products.compact!    
    end
    sorted_products
  end 

  def self.init(number_clusters, products, weights)
    specs = self.factorize_cont_data(products)
    centers = [specs[(specs.size-1)/2]]
    for j in (0...number_clusters-1)
      actual_dists = centers.map{|c| specs.map{|s| self.distance(c,s, weights)}}.transpose.map{|j| j.min}
        centers << specs[actual_dists.index(actual_dists.max)]
    end  
    centers.map{|c| specs.index(c)} 
  end
  
  def self.set_cluster_weights(features)
      weights = features.map{|f| f.value}
      weights_sum = weights.sum.to_f
      weights.map{|w| w/weights_sum}
  end
  
  def self.utility(products, use)
    if use == "rep"
      products.map{|p| p.instance_variable_get("@utility")}
    elsif use == "gorder"
      products.map{|i| i.instance_variable_get("@#{Session.search.sortby || "utility"}") || 0}
    end    
  end
  
  # regular kmeans function     
  ## ruby function only cluster based on continuous data 
  ## ruby function does not sort by utility and don't pick the highest utility as the rep
  
  #$k.kmeans_c(standard_specs.flatten.map{|s| s.nil? ? 0.0 : s}, standard_specs.size , standard_specs.first.size, number_clusters, cluster_weights, utilities_rep, utilities_gorder, inits)
  
  def self.ruby(number_clusters, cluster_weights, inits, products)
    thresh = 0.000001
    standard_specs = self.factorize_cont_data(products)
    mean_1 = inits.map{|i| standard_specs[i]}
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
     labels = labels.map{|l| labels.uniq.index(l)} if labels.uniq.size <labels.max+1
     # split if there is only one cluster
     if labels.uniq.size ==1
       (0...number_clusters-1).to_a.each{|i| labels[i] = i}
       (number_clusters-1...labels.size).to_a.each{|i| labels[i] = number_clusters -1}
     end
    #ordering clusters based on group utility 
    self.utility_order(products, labels, labels.uniq.size)
  end
  
  
  def self.utility_order(products, labels, number_clusters)
    utilitylist = Kmeans.utility(products, "gorder")
    utilitylist.each_with_index{|u, i| utilitylist[i]=u+(0.0000001*i)} if utilitylist.uniq.size<number_clusters
    grouped_utilities = group_by_labels(utilitylist, labels)
    avg_group_utilities = grouped_utilities.map do |g| 
      g.sum/(g.size.to_f)
    end  
    sorted_group_utilities = avg_group_utilities.sort{|x,y| y<=>x}
    sorted_grouped_utilities = sorted_group_utilities.map{|g| grouped_utilities[avg_group_utilities.index(g)]}
    sorted_labels  = labels.map{|l| sorted_group_utilities.index(avg_group_utilities[l])} 
    sorted_labels 
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
    points.transpose.map do |p| 
      myp = p.compact
      myp.empty? ? nil : myp.sum/myp.size.to_f
    end
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
    dim == 0.0 ? 0 : dist/dim
  end
    
def self.factorize_cont_data(products)
  Session.features["cluster"].map{|f| products.map{|p| p.instance_variable_get("@#{f.name}_factor")}}.transpose
end
  
  def self.factorize_cont(product)
    Session.features["cluster"].map{|f| product.instance_variable_get("@#{f.name}_factor")}
  end
  
  def self.betterproducts(curr_set)
    set = ComparableSet.new
    min_utility = curr_set.mapfeat("utility").min
    ContSpec.all.each do |rec|
      #only include new products
      next if curr_set.include_id?(rec.product_id) 
      prod = ProductAndSpec.new(:id => rec.product_id)
      prod.set(rec.names, rec.vals)
      #only include better products
      set.add(prod) if prod.utility > min_utility
    end
    set
  end
    
  def self.extendedCluster(expected_num,products)
    better_set = Kmeans.betterproducts(products)
    
    dim = Session.features["cluster"].size
    weights = [1.0/dim]*dim
    
    dists = better_set.map do |better| 
      s2 = Kmeans.factorize_cont(better)
      better.dist = products.map do |curr| 
        s1 = Kmeans.factorize_cont(curr)
        self.distance(s1,s2,weights)
      end.sum
    end
    
    threshold = dists.sort[expected_num]
    #Remove some products if there are more than expected
    better_set.reject!{|p| p.dist >= threshold} unless threshold.nil?
    better_set
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
