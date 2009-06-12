require 'test_helper'
require 'compare_controller'

class CompareControllerTest < ActionController::TestCase
   
  def test_empty_compare_list_redirects_to_start_page
      get :index
      if( assigns("saveds").length == 0 && assigns("products").length == 0) 
          assert_redirected_to :controller => "printers", :action => "index"
      else
          flunk, "Can't load empty list"
      end
  end

end
