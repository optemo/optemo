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
    @products = []
    @utility = []
    @products << Printer.find(:first, :conditions => ['price = 1000'])
    @products << Printer.find(:first, :conditions => ['price = 2000'])
    
ReorderProducts()    
#    assert_equal(@products[0].send('id'), 1)
assert_equal(@sortedProducts[0].send('id'), 2)

  end
end
