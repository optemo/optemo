require 'test_helper'

class CameraClusterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def setup
    #called before each test method is run
  end
  def test_children
    first_cluster = CameraCluster.find(1)
    assert first_cluster.children.length == 2
  end
  def test_representative
    c = CameraCluster.first
    assert c.representative.asin == "www.amazon.com/1"
  end  
end