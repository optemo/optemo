require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  test "Get Image Url" do
    prod1 = create(:product, :sku=>"10179458")
    prod2 = create(:product, :sku=>"10181681")
    prod3 = create(:product, :sku=>"10171799")
    
    assert_equal "http://www.bestbuy.ca/multimedia/Products/55x55/101/10179/10179458.jpg", prod1.image_url(:thumbnail)
    assert_equal "http://www.bestbuy.ca/multimedia/Products/250x250/101/10181/10181681.jpg", prod2.image_url(:large)
    assert_equal "http://www.bestbuy.ca/multimedia/Products/100x100/101/10171/10171799.jpg", prod3.image_url(:small)
    assert_equal "http://www.bestbuy.ca/multimedia/Products/150x150/101/10171/10171799.jpg", prod3.image_url(:medium)
    assert_not_equal "http://www.bestbuy.ca/multimedia/Products/150x150/101/10171/10171799.jpg", prod3.image_url(:thumbnail)
  end
end
