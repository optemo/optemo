require 'test_helper'

class SearchTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_distribution
    searchM = Search.first
    dist = searchM.distribution("displaysize")
    assert dist.length == 10, "Failed to have 10 bins"
    assert dist.sum.to_f >= 0.999 && dist.sum.to_f <= 1.001, "Failed to normalize"
    
  end
  def test_ranges
    searchM = Search.first
    assert searchM.ranges("displaysize") == [1.5, 1.5], "Failed to get the range"
  end
  
  def test_result_count
    searchM = Search.first
    assert searchM.result_count == 44, "Failed to get the result count"
  end  
end
