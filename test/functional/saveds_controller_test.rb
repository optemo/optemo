require 'test_helper'

class SavedsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:saveds)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_saved
    assert_difference('Saved.count') do
      post :create, :saved => { }
    end

    assert_redirected_to saved_path(assigns(:saved))
  end

  def test_should_show_saved
    get :show, :id => saveds(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => saveds(:one).id
    assert_response :success
  end

  def test_should_update_saved
    put :update, :id => saveds(:one).id, :saved => { }
    assert_redirected_to saved_path(assigns(:saved))
  end

  def test_should_destroy_saved
    assert_difference('Saved.count', -1) do
      delete :destroy, :id => saveds(:one).id
    end

    assert_redirected_to saveds_path
  end
end
