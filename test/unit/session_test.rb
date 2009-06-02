require 'test_helper'

class SessionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_clearFilters
    one = Session.first
    one.clearFilters
    assert one.brand == "All Brands"
    assert one.price_max == Session.columns_hash["price_max"].default
  end
end
