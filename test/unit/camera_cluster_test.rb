require 'test_helper'
require 'cluster'
class CameraClusterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def setup
    #called before each test method is run
  end
  def test_children
    first_cluster = CameraCluster.find(1)
    session = Session.first
    assert first_cluster.children(session).length == 2
  end
  def test_size
    c = CameraCluster.first
    session = Session.first
    assert c.size(session) == 2
  end
  def test_representative
    c = CameraCluster.first
    s = Session.first
    s2 = Session.find(2)
    assert c.representative(s).asin == "www.amazon.com/1", "First product"
    assert c.representative(s2).asin == "www.amazon.com/2", "Second product"
  end
  def test_isEmpty
    c = CameraCluster.first
    s = Session.first
    s2 = Session.find(3)
    filters = Cluster.findFilteringConditions(s)  
    filters2 = Cluster.findFilteringConditions(s2)  
    assert !c.isEmpty(filters, s.product_type) 
    assert c.isEmpty(filters2, s2.product_type), "thinks it is not empty" 
  end  
end