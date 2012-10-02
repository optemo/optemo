require 'test_helper'

class RangesTest < ActiveSupport::TestCase

  test "modify ranges function" do
    ret = Ranges.modifyRanges([],[])
    assert_equal 0, ret.length
  end
  
  test "modify ranges case 1" do
    # ____*********_____
    # xxxx__xx_____xxxxx
    selected = [ (5..10) ]
    ranges = [ (1..5), (7..8), (10..14)]
    expected_ranges = [(1..4.9), (5..10), (10.1..14)]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end

  test "modify ranges case 2" do
    selected = [ (5..10) ]
    ranges = [ (1..3), (3..8), (8..10)]
    expected_ranges = [ (1..3), (3..4.9), (5..10) ]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
  test "modify ranges case 3" do
    selected = [ (5..10) ]
    ranges = [ (5..8), (8..11), (12..13) ]
    expected_ranges = [(5..10), (10.1..11), (12..13)]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
  test "modify ranges case 4" do  
    selected = [ (5..10) ]
    ranges = [ (2..12) ]
    expected_ranges = [(2..4.9), (5..10), (10.1..12)]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
  test "modify ranges case 5" do
    # case 5
    selected = [ (4..5.9), (6..7), (10..16) ]
    ranges = [ (5..8) ]
    expected_ranges = [4..5.9, 6..7, 7.1..8, 10..16]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
  test "modify ranges case 6" do
    # case 6
    selected = [ (4..6), (6..7), (10..16) ]
    ranges = [ (7..10) ]
    expected_ranges = [ (4..6), (6..7), (7.1..9.9), (10..16) ]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
  test "modify ranges case 7" do
    selected = [ (4..6), (6.5..7), (10..16) ]
    ranges = [ (7..11) ]
    expected_ranges = [ (4..6), (6.5..7), (7.1..9.9), (10..16) ]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
  test "modify ranges case 8" do
    selected = [ (4..6), (6..7), (10..16) ]
    ranges = [ (6..18) ]
    expected_ranges = [ (4..6), (6..7), (7.1..9.9), (10..16), (16.1..18) ]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
  test "modify ranges case 9" do
    selected = [ (4..6), (6..7), (10..16) ]
    ranges = [ 4..4, 11..11, 16..16]
    expected_ranges = [ (4..6), (6..7), (10..16) ]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
  test "modify ranges case 10" do
    selected = [ (4..4), (7..7), (11..11), (14..14) ]
    ranges = [ 4..4, 5..7, 11..12, 13..16 ]
    expected_ranges = [ (4..4), (5..6.9), (7..7), (11..11), (11.1..12), (13..13.9), (14..14), (14.1..16) ]
    assert_equal expected_ranges, Ranges.modifyRanges(selected, ranges)
  end
  
end