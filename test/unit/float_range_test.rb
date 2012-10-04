require 'test_helper'

class FloatRangeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "Initialization" do
    min = 3.1
    max = 4.5
    f = FloatRange.new(min,max)
    assert_equal min, f.min
    assert_equal max, f.max
    assert_equal nil, f.unit
  end
  
  test "prettify" do
    min = 3.0
    max = 3.0
    f = FloatRange.new(min,max,"saleprice")
    assert_equal "$3", f.to_s
  end
  
  test "capacity correction" do
    min = 3000
    max = 3000
    f = FloatRange.new(min,max,"capacity")
    assert_equal "3 TB", f.to_s
  end
  
  test "prettify range" do
    min = 3.0
    max = 4.5
    f = FloatRange.new(min,max,"saleprice")
    assert_equal "$3 - $4.50", f.to_s
  end
  
  test "capacity range" do
    min = 3000
    max = 4600
    f = FloatRange.new(min,max,"capacity")
    assert_equal "3 - 4.6 TB", f.to_s
  end
end