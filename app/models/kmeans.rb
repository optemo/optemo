 class  Kmeans
 require 'rubygems'
 
 def self.compute(number_clusters,p_ids)
 
  dim_cont = Session.continuous["cluster"].size
  dim_bin = Session.binary["cluster"].size
  dim_cat = Session.categorical["cluster"].size
  weights = self.set_weights(dim_cont, dim_bin, dim_cat)
  s = p_ids.size
  ft = [] 
  # don't need to cluster if number of products is less than clusters

  if (s<number_clusters)
    if ft.empty?
      utilitylist = [1]*s
    else  
      utilitylist = weighted_ft(ft, weights).map{|f| f. inject(:+)}
    end  
    #if utilities are the same
    utilitylist.each_with_index{|u, i| utilitylist[i]=u+(0.0000001*i)} if utilitylist.uniq.size<s
    util_tmp = utilitylist.sort{|x,y| y <=> x }    
    ordered_list = util_tmp.map{|u| utilitylist.index(u)}
    return ordered_list + ordered_list
  end
 
  st = Product.specs(p_ids)
  cont_specs = st[0...dim_cont].transpose
  bin_specs = st[dim_cont...dim_cont+dim_bin].transpose
  cat_specs = st[dim_cont+dim_bin...st.size].transpose 

    factors =[]
    Session.continuous["cluster"].each do |f| 
      f_specs = ContSpec.by_feat(f+"_factor")
      factors << f_specs
    end
     
    performance_factors = ContSpec.by_feat("performance_factor")
    #factors << performance_factors
    ft = factors.transpose
    #factors << [1]*factors.first.size
  
    performance_weight = 2
    #weights = weights << performance_weight
    weight_dim = dim_cont+dim_bin+dim_cat+1
    # dimension of each category - for example how many different brands 
    dim_per_cat = cat_specs.first.map{|f| f.size}
    # inistial seeds for clustering  ### just based on contiuous features
    inits = self.init(number_clusters, cont_specs, weights[0...dim_cont])
    Kmeans.ruby(number_clusters, cont_specs, ft, weights[0...dim_cont], inits)
    
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
  if Session.search.sortby=='Price' # price is selected as prefered order
    weights = [0.01/(dim-1)]*dim  
    weights[Session.continuous["cluster"].index('price')] = 0.99    
  else
    weights = [1.0/dim]*dim
  end
  weights                         
end


# regular kmeans function     
## ruby function only cluster based on continuous data 
## ruby function does not sort by utility and don't pick the highest utility as the rep
def self.ruby(number_clusters, specs, ft, weights, inits)
  weights = [1]*specs.first.size if weights.nil?
  thresh = 0.000001
  standard_specs = self.standardize_cont_data(specs)
  #mean_1 = self.seed(number_clusters, specs)
  mean_1 = inits.map{|i| standard_specs[i]}
  mean_2 =[]
  labels = []
  dif = []
  begin 
   mean_2 = mean_1 
   standard_specs.each_index do |i| 
     mean_1.each_index do |c|
       dif[c] = self.distance(standard_specs[i], mean_1[c], weights)
     end
     labels[i] = dif.index(dif.min)
   end 
   mean_1= self.means(number_clusters, standard_specs, labels)
   z=0.0;
   mean_1.each_index{|c| z+=self.distance(mean_1[c], mean_2[c], weights)}
  end while z > thresh
  reps = [];

  #utility ordering
  #if Session.search.sortby=='Price'
    
  
  utilitylist = weighted_ft(ft, weights).map{|f| f. inject(:+)}  
  grouped_utilities = group_by_labels(utilitylist, labels).map{|g| g.inject(:+)}
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