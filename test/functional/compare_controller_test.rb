require 'test_helper'

class CompareControllerTest < ActionController::TestCase
  setup do
    # Make sure we setup Sunspot again now that the Facet fixtures have been loaded.
    Product.setup_sunspot
  end

  test "Search creation and lookup" do 
    assert_equal 0, Search.all.size
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"brand"=>"canon", "product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal "G3TB8NnvXOhpN8nF8eB6Cw==", assigns(:params_hash)
    assert_equal 1, Search.all.size, "A search was created"

    # Parameter order should not matter
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"product_type"=>"B22474", "brand"=>"canon"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal "G3TB8NnvXOhpN8nF8eB6Cw==", assigns(:params_hash)
    assert_equal 1, Search.all.size, "Existing search was reused"

    # If a search matches the hist parameter, we use that search.
    get :index, {"hist" => "G3TB8NnvXOhpN8nF8eB6Cw=="}
    assert_response :success
    assert_equal "G3TB8NnvXOhpN8nF8eB6Cw==", assigns(:params_hash)
    assert_equal 1, Search.all.size, "Existing search was reused"

    # If no search matches the hist parameter, we create a new search.
    get :index, {"hist" => "junk", "ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal "GS33TKL28CPVcsFs1EVuvg==", assigns(:params_hash)
    assert_equal 2, Search.all.size, "A new search was created"
  end

  test "Updating the updated_at field of existing search" do
    assert_equal 0, Search.all.size
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"brand"=>"canon", "product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal "G3TB8NnvXOhpN8nF8eB6Cw==", assigns(:params_hash)
    assert_equal 1, Search.all.size, "A search was created"
    search = Search.all[0]

    # Temporarily disable automatic updating of updated_at.
    Search.record_timestamps = false
    search.updated_at = Time.now.utc - 2 * 24 * 60 * 60
    search.save
    Search.record_timestamps = true
    old_updated_at = Search.all[0].updated_at

    # Default update interval is 1 day, so if we access the search after 2 days,
    # the updated_at value should be updated.
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"brand"=>"canon", "product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal "G3TB8NnvXOhpN8nF8eB6Cw==", assigns(:params_hash)
    assert_equal 1, Search.all.size, "The existing search was reused"
    search = Search.all[0]
    assert_not_equal old_updated_at, search.updated_at, "Updated_at field was changed"
    old_updated_at = search.updated_at 

    sleep 2

    # Accessing it again after a short period should not result in a change to the updated_at field.
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"brand"=>"canon", "product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal "G3TB8NnvXOhpN8nF8eB6Cw==", assigns(:params_hash)
    assert_equal 1, Search.all.size, "The existing search was reused"
    search = Search.all[0]
    assert_equal old_updated_at, search.updated_at, "Updated_at field did not change"
  end
end


