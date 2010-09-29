require 'test_helper'

class ClusterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "Product deletion works" do
    init_facts
    assert Node.count == 39, "There's not 39 initial nodes"
    Node.first.delete
    assert Node.count == 38, "Node deletion doesn't work"
  end
  
  test "parent cluster" do
    init_facts
    assert Node.count == 39, "There's not 39 initial nodes"
    #assert_not_nil Cluster.byparent(0), "No cluster with id 0 found"
    #assert_not_nil Cluster.byparent(0).length == 1, "Didn't find any or more than one cluster"
    assert Product.count == 16, "Not 16 products only #{Product.count}"
  end
  
  test "Get cluster by parent ID" do
    init_facts
    level1 = Cluster.byparent(0)
    level2 = Cluster.byparent(Cluster.all[2].id)
    level5 = Cluster.byparent(Cluster.last.id+1)
    #puts level1.size
    #debugger
    assert level1.size == 9, "There's not 9 clusters in level 1"
    assert level2.size == 1, "There's not 1 cluster in the second groups children"
    assert level5.empty?, "Cluster.byparent is not returning an empty list when in should"
  end
  
  test "Max 9 children" do
    init_facts
    Cluster.all.each do |c|
      assert c.children.size <= 9, "There more than 9 children for cluster #{c.id}"
    end
  end
  
  test "Empty filtering results" do
    init_facts
    firstcluster = Cluster.first
    Factory(:cont_spec, :name => "price", :product_id => Product.first.id, :value => 700)
    mysearch = Search.new "price_max" => 800, "price_min" => 750, "clusters" => nil #Cluster nil means that it should not reset filters and load initial clusters
    assert firstcluster.isEmpty(mysearch), "Search should be empty with restrictive filtering applied"
  end
  
  test "Nodes is returning the correct children" do
    init_facts
    secondcluster = Cluster.all[1]
    product_ids = secondcluster.nodes.map(&:product_id)
    correct_product_ids = [Product.all[2-1].id,Product.all[10-1].id,Product.all[15-1].id]
    #debugger
    assert_equal correct_product_ids, product_ids, "Nodes did not return the correct second cluster nodes"
  end
end
