require 'test_helper'
require 'compare_controller'

class CompareControllerTest < ActionController::TestCase
   
#  def test_empty_compare_list_redirects_to_start_page
#      get :index
#      if( assigns("saveds").length == 0 && assigns("products").length == 0) 
#          assert_redirected_to :controller => "printers", :action => "index"
#      else
#          flunk "Can't load empty list"
#      end
#  end

  def test_ReorderProducts
    session[:productType] = 'Printer'
    session[:user_id] = 5
    @products = []
    @utility = []
    
    # Add 2 printers
    @products << Printer.find(:first, :conditions => ['price = 2000'])
    assert_equal(@products[0].send('id'), 6)
    @products << Printer.find(:first, :conditions => ['price = 1000'])
    assert_equal(@products[1].send('id'), 5)
    # Test the ReorderProducts() function
    ReorderProducts()    
    assert_equal(@sortedProducts[0].send('id'), 5)

    # ToDo: Test ReorderProducts() for product_type = Camera
  end
  
  def test_numberOfStars
    utility = 0.08
    assert_equal(numberOfStars(utility), 0.5)
    
    utility = 0.13
    assert_equal(numberOfStars(utility), 1)
    
    utility = 0.218
    assert_equal(numberOfStars(utility), 1.5)
    
    utility = 0.299
    assert_equal(numberOfStars(utility), 1.5)
    
    utility = 0.3
    assert_equal(numberOfStars(utility), 1.5)
    
    utility = 0.31
    assert_equal(numberOfStars(utility), 2)
    
    utility = 0.99
    assert_equal(numberOfStars(utility), 5)    
  end
end
