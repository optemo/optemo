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
    
    assert_equal prod1.image_url(:thumbnail), "http://www.bestbuy.ca/multimedia/Products/55x55/101/10179/10179458.jpg"
    assert_equal prod2.image_url(:large), "http://www.bestbuy.ca/multimedia/Products/250x250/101/10181/10181681.jpg"
    assert_equal prod3.image_url(:small), "http://www.bestbuy.ca/multimedia/Products/100x100/101/10171/10171799.jpg"
    assert_equal prod3.image_url(:medium), "http://www.bestbuy.ca/multimedia/Products/150x150/101/10171/10171799.jpg"
    assert_not_equal prod3.image_url(:thumbnail), "http://www.bestbuy.ca/multimedia/Products/150x150/101/10171/10171799.jpg"
  end
end
