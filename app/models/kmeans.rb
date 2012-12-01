class  Kmeans
  def self.compute(number_clusters,data)
    s = data.size
    inits = self.init(number_clusters, data)
    labels = self.ruby(number_clusters,inits, data) 
    data.mygroup_by{|e,i|labels[i]}
  end 

  def self.init(number_clusters, data)  
   #based on the assumption that the data is sorted we are picking centers considering the distribution
   centers = []
   uniq_data = data.uniq
   s = uniq_data.size
   m = s.to_f/number_clusters
   for j in (1..number_clusters) 
     centers << uniq_data[(m*j).to_i-1]
   end    
   centers.map{|c| data.index(c)} 
  end
  
  # regular kmeans function     
  ## ruby function only cluster based on continuous data 
  ## ruby function does not sort by utility and don't pick the highest utility as the rep
  
  
  def self.ruby(number_clusters, inits, products)
    thresh = 0.001
    standard_specs = products #self.factorize_cont_data(products)
    mean_1 = inits.map{|i| standard_specs[i]}
    labels = []
    dif = []
    begin 
      mean_2 = mean_1 
      standard_specs.each_index do |i| 
        mean_1.each_index do |c|
          dif[c] = self.distance(standard_specs[i], mean_1[c])
        end
        labels[i] = dif.index(dif.min)
      end 
      mean_1= self.means(number_clusters, standard_specs, labels)
      z=0.0;
      mean_1.each_index do |c|
        mean_1[c] = 0 if mean_1[c].nil?
        mean_2[c] = 0 if mean_2[c].nil?
        debugger if mean_2[c].nil?
        z+=self.distance(mean_1[c], mean_2[c])
      end    
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
  def self.mean(points)
    points.empty? ? nil : points.sum/points.size
  end
  
  # Finding the means of all clusters
  # Group the specs based on their labels and within each group, find their mean
  def self.means(number_clusters, specs, labels)
    #specs.mygroup_by{|e,i|labels[i]}.map{|s|self.mean(s)}
    uniq_labels = labels.uniq
    grouped = {}
    uniq_labels.each{|l| grouped[l] = []}
    labels.each_with_index{|l,i| grouped[l] << specs[i]} 
    uniq_labels.map{|l| self.mean(grouped[l])}
  end
  
  #Euclidian distance function
  def self.distance(point1, point2)
    dist =(point1-point2)*(point1-point2)
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
