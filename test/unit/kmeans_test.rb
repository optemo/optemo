require 'test_helper'

class KmeansTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  setup do
    Session.new
    create(:typed_product, id: 10, sku:10159584)
    create(:typed_product, id: 11, sku:10159585)
    create(:typed_product, id: 12, sku:10159586)
    create(:typed_product, id: 13, sku:10159587)
  end

  test "the truth" do
    assert true
  end
end
