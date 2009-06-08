require 'test_helper'

class SessionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_clearFilters
    Session.first.clearFilters
    one = Session.first
    assert one.brand == "All Brands"
    assert one.price_max == Session.columns_hash["price_max"].default
  end
end
