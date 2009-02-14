require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  #Test Instantiations
  Cheap = Hash[
    "brand", "All Brands",
    "maximumresolution_min", 0.0,
    "maximumresolution_max", 14.7,
    "opticalzoom_min", 0,
    "opticalzoom_max", 20,
    "displaysize_min", 0,
    "displaysize_max", 3.6,
    "price_min", 0,
    "price_max", 30000]
  HighZoom = Hash[
    "brand", "All Brands",
    "maximumresolution_min", 0.0,
    "maximumresolution_max", 14.7,
    "opticalzoom_min", 10,
    "opticalzoom_max", 20,
    "displaysize_min", 0,
    "displaysize_max", 3.6,
    "price_min", 0,
    "price_max", 181586]
  Canon = Hash[
    "brand", "Canon",
    "maximumresolution_min", 0.0,
    "maximumresolution_max", 14.7,
    "opticalzoom_min", 0,
    "opticalzoom_max", 20,
    "displaysize_min", 0,
    "displaysize_max", 3.6,
    "price_min", 0,
    "price_max", 181586]
  Small = Hash[
    "brand", "Canon",
    "maximumresolution_min", 2.6,
    "maximumresolution_max", 6.0,
    "opticalzoom_min", 0,
    "opticalzoom_max", 7,
    "displaysize_min", 0,
    "displaysize_max", 2,
    "price_min", 400,
    "price_max", 51586]
  HighMPSmallD = Hash[
    "brand", "All Brands",
    "maximumresolution_min", 8.1,
    "maximumresolution_max", 14.7,
    "opticalzoom_min", 0,
    "opticalzoom_max", 20,
    "displaysize_min", 0,
    "displaysize_max", 2.4,
    "price_min", 400,
    "price_max", 181586]
  
  
  def test_index
    oldsearch = session[:search_id] if !session.empty?
    get :index
    assert_response :redirect
    
    assert_not_equal(assigns(:output),"","No output from connect program")
    assert_equal(assigns(:badparams),"None","Extra output from connect")
    assert_not_equal(oldsearch, session[:search_id], "Search was not successful, output: #{assigns(:output)}}")
  end
  
  def test_filter_cheap
    get :index
    oldsearch = session[:search_id]
    assert_equal(assigns(:badparams),"None","Extra output from connect")
    post :filter, :myfilter => Cheap
    assert_response :redirect
    assert_equal(assigns(:badparams),"None","Extra output from connect")
    assert_not_equal(oldsearch, session[:search_id], "Search was not successful, output: #{assigns(:output)}")
    s = Search.find(session[:search_id])
    "i0".upto("i8") do |i|
      assert_match(/\d+/,s.send(i.intern).to_s,"Returned id(#{i}) not a number: #{s.send(i.intern).to_s}")
      assert_in_delta(1000,s.send(i.intern),1000,"Not a valid product id(#{i}) greater than 2000 or less than 0: #{s.send(i.intern).to_s}")
    end
  end
  
  def test_filter_highzoom
    get :index
    oldsearch = session[:search_id]
    post :filter, :myfilter => HighZoom
    assert_response :redirect
    assert_not_equal(oldsearch, session[:search_id], "Search was not successful, output: #{assigns(:output)}")
    s = Search.find(session[:search_id])
    "i0".upto("i8") do |i|
      assert_match(/\d+/,s.send(i.intern).to_s,"Returned id(#{i}) not a number: #{s.send(i.intern).to_s}")
      assert_in_delta(1000,s.send(i.intern),1000,"Not a valid product id(#{i}) greater than 2000 or less than 0: #{s.send(i.intern).to_s}")
    end
  end
  
  def test_filter_canon
    get :index
    oldsearch = session[:search_id]
    post :filter, :myfilter => Canon
    assert_response :redirect
    assert_not_equal(oldsearch, session[:search_id], "Search was not successful, output: #{assigns(:output)}")
    s = Search.find(session[:search_id])
    "i0".upto("i8") do |i|
      assert_match(/\d+/,s.send(i.intern).to_s,"Returned id(#{i}) not a number: #{s.send(i.intern).to_s}")
      assert_in_delta(1000,s.send(i.intern),1000,"Not a valid product id(#{i}) greater than 2000 or less than 0: #{s.send(i.intern).to_s}")
    end
  end
  
  def test_filter_small
    get :index
    oldsearch = session[:search_id]
    post :filter, :myfilter => Small
    assert_response :redirect
    assert_not_equal(oldsearch, session[:search_id], "Search was not successful, output: #{assigns(:output)}")
    s = Search.find(session[:search_id])
    "i0".upto("i8") do |i|
      assert_match(/\d+/,s.send(i.intern).to_s,"Returned id(#{i}) not a number: #{s.send(i.intern).to_s}")
      assert_in_delta(1000,s.send(i.intern),1000,"Not a valid product id(#{i}) greater than 2000 or less than 0: #{s.send(i.intern).to_s}")
    end
  end
  
  def test_filter_HighMPSmallD
    get :index
    oldsearch = session[:search_id]
    post :filter, :myfilter => HighMPSmallD
    assert_response :redirect
    assert_not_equal(oldsearch, session[:search_id], "Search was not successful, output: #{assigns(:output)}")
    s = Search.find(session[:search_id])
    "i0".upto("i8") do |i|
      assert_match(/\d+/,s.send(i.intern).to_s,"Returned id(#{i}) not a number: #{s.send(i.intern).to_s}")
      assert_in_delta(1000,s.send(i.intern),1000,"Not a valid product id(#{i}) greater than 2000 or less than 0: #{s.send(i.intern).to_s}")
    end
  end
end
