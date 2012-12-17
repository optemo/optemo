require 'test_helper'

class CompareControllerTest < ActionController::TestCase
  setup do
    # Make sure we setup Sunspot again now that the Facet fixtures have been loaded.
    Product.setup_sunspot
  end

  test "Search creation and lookup" do 
    expected_hash = "lxSoWHh50MHSnCjx5J4E4g"

    assert_equal 0, Search.all.size
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"brand"=>"canon", "product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal 1, Search.all.size, "A search was created"
    assert_equal expected_hash, Search.all[0].params_hash
    assert_not_nil Session.search
    assert_equal expected_hash, Session.search.params_hash

    # Parameter order should not matter
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"product_type"=>"B22474", "brand"=>"canon"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal 1, Search.all.size, "Existing search was reused"
    assert_not_nil Session.search
    assert_equal expected_hash, Session.search.params_hash

    # Parameters which are not used to construct the search should not matter.
    get :index, {"ajax"=>"false", "category_id"=>"B20218", "categorical"=>{"product_type"=>"B22474", "brand"=>"canon"}, 
                 "expanded" => {"brand" => "true"}}
    assert_response :success
    assert_equal 1, Search.all.size, "Existing search was reused"
    assert_not_nil Session.search
    assert_equal expected_hash, Session.search.params_hash

    # The 'expanded' parameter was used to initialize the 'expanded' field in the search that was retrieved from the 
    # database.
    assert_nil Search.all[0].expanded
    assert_not_nil Session.search.expanded
    assert_true Session.search.expanded.include? "brand"

    # If a search matches the hist parameter, we use that search.
    get :index, {"hist" => expected_hash}
    assert_response :success
    assert_equal 1, Search.all.size, "Existing search was reused"
    assert_not_nil Session.search
    assert_equal expected_hash, Session.search.params_hash

    # Lookup of existing searches using hist parameter is case-sensitive.
    get :index, {"hist" => expected_hash.downcase!}
    assert_response :success
    assert_equal 2, Search.all.size, "A new search was created"
    assert_not_nil Session.search

    # If no search matches the hist parameter, we create a new search.
    get :index, {"hist" => "junk", "ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal 3, Search.all.size, "A new search was created"
    assert_not_nil Session.search
    assert_equal "as5c7rKv8yFpJfvZ2hqrEw", Session.search.params_hash
  end

  test "Updating the updated_at field of existing search" do
    expected_hash = "lxSoWHh50MHSnCjx5J4E4g"

    assert_equal 0, Search.all.size
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"brand"=>"canon", "product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal 1, Search.all.size, "A search was created"
    search = Search.all[0]
    assert_equal expected_hash, search.params_hash

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
    assert_equal 1, Search.all.size, "The existing search was reused"
    search = Search.all[0]
    assert_equal expected_hash, search.params_hash
    assert_not_equal old_updated_at, search.updated_at, "Updated_at field was changed"
    old_updated_at = search.updated_at 

    sleep 2

    # Accessing it again after a short period should not result in a change to the updated_at field.
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"brand"=>"canon", "product_type"=>"B22474"}, 
                 "is_quebec"=>"false"}
    assert_response :success
    assert_equal 1, Search.all.size, "The existing search was reused"
    search = Search.all[0]
    assert_equal expected_hash, search.params_hash
    assert_equal old_updated_at, search.updated_at, "Updated_at field did not change"

    # Test the case where the search is retrieved using the hash.
    Search.record_timestamps = false
    search.updated_at = Time.now.utc - 2 * 24 * 60 * 60
    search.save
    Search.record_timestamps = true
    old_updated_at = Search.all[0].updated_at

    get :index, {"hist" => expected_hash}
    assert_response :success
    assert_equal 1, Search.all.size, "The existing search was reused"
    search = Search.all[0]
    assert_equal expected_hash, search.params_hash
    assert_not_equal old_updated_at, search.updated_at, "Updated_at field was changed"

  end
  
  test "Session features set correctly based on product type" do
    get :index, {"ajax"=>"true", "category_id"=>"B20005"}
    assert_response :success
    features = Session.features.values.flatten
    assert_not_nil features
    assert_nil features.find{ |facet| facet.name == "brand" }
    assert_nil features.find{ |facet| facet.name == "saleprice" }
    assert_nil features.find{ |facet| facet.name == "onsale" }

    get :index, {"ajax"=>"true", "category_id"=>"B20218"}
    assert_response :success
    features = Session.features.values.flatten
    assert_not_nil features
    assert_not_nil features.find{ |facet| facet.name == "brand" }
    assert_not_nil features.find{ |facet| facet.name == "saleprice" }
    assert_not_nil features.find{ |facet| facet.name == "onsale" }
    
    # frontlcd is a dynamic facet only available if the B22474 subcategory is selected
    assert_nil features.find{ |facet| facet.name == "frontlcd" }
    
    # If B22474 is selected, we should get the facets of the landing page (B20218) plus the dynamic facet frontlcd
    get :index, {"ajax"=>"true", "category_id"=>"B20218", "categorical"=>{"product_type"=>"B22474"}}
    assert_response :success
    features = Session.features.values.flatten
    assert_not_nil features
    assert_not_nil features.find{ |facet| facet.name == "brand" }
    assert_not_nil features.find{ |facet| facet.name == "saleprice" }
    assert_not_nil features.find{ |facet| facet.name == "onsale" }

    assert_not_nil features.find{ |facet| facet.name == "frontlcd" }
  end
  
  test "Session filters set correctly based on product type" do
    get :index, {"ajax"=>"true", "category_id"=>"B20005", "binary"=>{"onsale"=>"1"}, "categorical"=>{"brand"=>"canon"}, 
                 "continuous"=>{"saleprice"=>"100.0;150.0"}, "sortby"=>"utility_desc"}
    assert_response :success
    assert_not_nil Session.search
    assert_not_nil Session.search.userdatacats
    assert_not_nil Session.search.userdataconts
    assert_not_nil Session.search.userdatabins
    assert_nil Session.search.userdatacats.find{ |filter| filter.name == "brand" }
    assert_nil Session.search.userdataconts.find{ |filter| filter.name == "saleprice" }
    assert_nil Session.search.userdatabins.find{ |filter| filter.name == "onsale" }

    get :index, {"ajax"=>"true", "category_id"=>"B20218", "binary"=>{"onsale"=>"1", "frontlcd" => "1"}, "categorical"=>{"brand"=>"canon"}, 
                 "continuous"=>{"saleprice"=>"100.0;150.0"}, "sortby"=>"utility_desc"}
    assert_response :success
    assert_not_nil Session.search
    assert_not_nil Session.search.userdatacats
    assert_not_nil Session.search.userdataconts
    assert_not_nil Session.search.userdatabins
    assert_not_nil Session.search.userdatacats.find{ |filter| filter.name == "brand" }
    assert_not_nil Session.search.userdataconts.find{ |filter| filter.name == "saleprice" }
    assert_not_nil Session.search.userdatabins.find{ |filter| filter.name == "onsale" }

    # frontlcd is a dynamic facet only available if the B22474 subcategory is selected
    assert_nil Session.search.userdatabins.find{ |filter| filter.name == "frontlcd" }

    get :index, {"ajax"=>"true", "category_id"=>"B20218", "binary"=>{"onsale"=>"1", "frontlcd" => "1"}, "categorical"=>{"brand"=>"canon", "product_type"=>"B22474"}, 
                 "continuous"=>{"saleprice"=>"100.0;150.0"}, "sortby"=>"utility_desc"}
    # If B22474 is selected, the frontlcd filter should not be pruned.
    assert_response :success
    assert_not_nil Session.search
    assert_not_nil Session.search.userdatacats
    assert_not_nil Session.search.userdataconts
    assert_not_nil Session.search.userdatabins
    assert_not_nil Session.search.userdatacats.find{ |filter| filter.name == "product_type" }
    assert_not_nil Session.search.userdatacats.find{ |filter| filter.name == "brand" }
    assert_not_nil Session.search.userdataconts.find{ |filter| filter.name == "saleprice" }
    assert_not_nil Session.search.userdatabins.find{ |filter| filter.name == "onsale" }
    assert_not_nil Session.search.userdatabins.find{ |filter| filter.name == "frontlcd" }
  end
  
end


