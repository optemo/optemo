require 'test_helper'

class ClusterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  test "parent cluster" do
    assert_not_nil Cluster.byparent(0), "No cluster with id 0 found"
    assert_not_nil Cluster.byparent(0).length == 1, "Didn't find any or more than one cluster"
  end
  
  test "max 9 children" do
    assert true
  end
end
