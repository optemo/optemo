require 'test_helper'
require 'cluster'
class CameraClusterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def setup
    #called before each test method is run
  end
  def test_children
    first_cluster = CameraCluster.find('parent'.hash.abs)
    session = Session.first
    assert first_cluster.children(session).length == 2
  end
  def test_size
    c = CameraCluster.find('parent'.hash.abs)
    session = Session.first
    assert c.size(session) == 2
  end
  def test_representative
    c = CameraCluster.find('parent'.hash.abs)
    s = Session.first
    assert c.representative(s).asin == "www.amazon.com/1", "First product"
  end
  def test_representative_2
    c = CameraCluster.find('parent'.hash.abs)
    s2 = Session.find(2)
    assert c.representative(s2).asin == "www.amazon.com/2", "Second product"
  end
  def test_isEmpty_for_empty
    c = CameraCluster.find('parent'.hash.abs)
    s2 = Session.find(3)
    assert c.isEmpty(s2), "thinks it is not empty" 
  end
  
  def test_isEmpty_for_full
    c = CameraCluster.find('parent'.hash.abs)
    s = Session.first
    assert !c.isEmpty(s) 
  end 
end