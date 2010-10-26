require 'test_helper'

class ClusterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  #test "Product deletion works" do
  #  init_facts
  #  assert Node.count == 39, "There's not 39 initial nodes"
  #  Node.first.delete
  #  assert Node.count == 38, "Node deletion doesn't work"
  #end
  #
  #test "parent cluster" do
  #  init_facts
  #  assert Node.count == 39, "There's not 39 initial nodes"
  #  #assert_not_nil Cluster.byparent(0), "No cluster with id 0 found"
  #  #assert_not_nil Cluster.byparent(0).length == 1, "Didn't find any or more than one cluster"
  #  assert Product.count == 16, "Not 16 products only #{Product.count}"
  #end
  #
  #test "Get cluster by parent ID" do
  #  init_facts
  #  level1 = Cluster.byparent(0)
  #  level2 = Cluster.byparent(Cluster.all[2].id)
  #  level5 = Cluster.byparent(Cluster.last.id+1)
  #  #puts level1.size
  #  #debugger
  #  assert level1.size == 9, "There's not 9 clusters in level 1"
  #  assert level2.size == 1, "There's not 1 cluster in the second groups children"
  #  assert level5.empty?, "Cluster.byparent is not returning an empty list when in should"
  #end
  #
  #test "Max 9 children" do
  #  init_facts
  #  Cluster.all.each do |c|
  #    assert c.children.size <= 9, "There more than 9 children for cluster #{c.id}"
  #  end
  #end
  #
  #test "Empty filtering results" do
  #  init_facts
  #  firstcluster = Cluster.first
  #  Factory(:cont_spec, :name => "price", :product_id => Product.first.id, :value => 700)
  #  mysearch = Search.new "price_max" => 800, "price_min" => 750, "clusters" => nil #Cluster nil means that it should not reset filters and load initial clusters
  #  assert firstcluster.isEmpty(mysearch), "Search should be empty with restrictive filtering applied"
  #end
  
  #test "Nodes is returning the correct children" do
  #  init_facts
  #  secondcluster = Cluster.all[1]
  #  product_ids = secondcluster.nodes.map(&:product_id)
  #  correct_product_ids = [Product.all[2-1].id,Product.all[10-1].id,Product.all[15-1].id]
  #  #debugger
  #  assert_equal correct_product_ids, product_ids, "Nodes did not return the correct second cluster nodes"
  #end
  
  #-------
  
  test "Simple K-means assignment" do
    specs = [[0,0,1],[0,1,0],[1,0,0]]
    cluster_count = 3
    clusters = Cluster.kmeans(cluster_count,specs, [])
    assert_equal 3, clusters.uniq.size, "Generated clusters: #{clusters}"
  end
  #
  test "Simple K-means clustering" do
    specs = [[0,0,1],[0,1,0],[1,0,0],[0.5,0,0]]
    cluster_count = 3
    clusters = Cluster.kmeans(cluster_count,specs, [])
    assert_equal 3, clusters.uniq.size, "Generated clusters: #{clusters}"
    assert_equal clusters[2], clusters[3], "The last two products should be in the same cluster"
    assert_equal specs.size, clusters.size, "Kmeans should only return assignments for each of the points"
  end
 
  
  test "Indices function for finding indexes" do
    array = [0,1,0,2,1]
    ind = Cluster.indices(array, 1)
    assert_equal [1,4], ind, "indices is not coded right"    
  end
 
 
  test "Euclidian mean function" do 
   c0 =[[1.2, 2.4, 3], [2, 1, 0]]
   c1 = [[0.5, 1, 2], [1,0.8,0]]
   points = [c0[0], c0[1], c1[0], c1[1]]
   m = Cluster.mean(c0)
   number_clusters = 2
   labels = [0,1,1,0]
   ms = Cluster.means(number_clusters, points, labels)
   assert_equal [1.6, 1.7, 1.5], m, "mean function is buggy"
   assert_equal 2, ms.size, "means should be cxd arrary where c is the number of clusters and d is dimension"
   assert_equal [[1.1, 1.6, 1.5],[1.25, 1.0, 1.0]], ms, "mean should be calculated within each cluster"  
  end   
 
 
 
  test "Group according to clusteres" do
    product_ids = (1..7).to_a
    cluster_ids = [0,2,1,0,1,2,2]
    clusters = Cluster.group_by_clusterids(product_ids,cluster_ids)
    assert_equal [[2,6,7],[1,4],[3,5]], clusters, "Grouping should be ordered by size or groups"
  end
  
  test "Euclidian distance function" do
    point1 = [0.8,0.9,0.1]
    point2 = [0.7,0.2,0.3]
    assert_in_delta 0.54, Cluster.distance(point1, point2), 0.00001, "Euclidian distance calculation"
    assert_equal Cluster.distance(point1, point2), Cluster.distance(point2, point1), "Distance should be symmetric"
  end
  
# test "Standardization of continuous data" do 
#   points = [[0.1,2000], [0.5, 100], [0.3, 500]]
#   mean_all= Cluster.mean(points)
#   var_all = Cluster.get_var(points, mean_all)
#   assert_in_delta [0.3, 866.67], mean_all, 0.0001, "mean of points"
#   assert_in_delta [0.1643,817.8527], var_all, 0.0001, "variance of points" 
# end   
 
 #test "Data standardization" do 
 #  specs=[[2,3,1,"Canon"], [0, 1, 2, "Sony"]]
 #  assert_equal Cluster.standardize_data(specs).first.size, 5, "categorical features should be mapped to a an array"
 #  assert_equal [[2,3,1,1,0], [0,1,2,0,1]], Cluster.standardize_data(specs), "standardization is not done properly"
 #end  
end
