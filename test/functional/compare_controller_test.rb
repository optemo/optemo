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
end
