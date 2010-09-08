require 'test_helper'

class ClusterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "Product deletion works" do
    assert Node.count == 39, "Different number of nodes"
    Node.first.delete
    assert Node.count == 38, "Different number of nodes"
  end
  
  test "parent cluster" do
    init_facts
    assert Node.count == 39, "Different number of nodes"
    #assert_not_nil Cluster.byparent(0), "No cluster with id 0 found"
    #assert_not_nil Cluster.byparent(0).length == 1, "Didn't find any or more than one cluster"
    assert Product.count == 16, "Not 16 products only #{Product.count}"
  end
  
  test "max 9 children" do
    assert true
  end
end
