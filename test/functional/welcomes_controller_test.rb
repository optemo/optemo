require 'test_helper'

class WelcomesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:welcomes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_welcome
    assert_difference('Welcome.count') do
      post :create, :welcome => { }
    end

    assert_redirected_to welcome_path(assigns(:welcome))
  end

  def test_should_show_welcome
    get :show, :id => welcomes(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => welcomes(:one).id
    assert_response :success
  end

  def test_should_update_welcome
    put :update, :id => welcomes(:one).id, :welcome => { }
    assert_redirected_to welcome_path(assigns(:welcome))
  end

  def test_should_destroy_welcome
    assert_difference('Welcome.count', -1) do
      delete :destroy, :id => welcomes(:one).id
    end

    assert_redirected_to welcomes_path
  end
end
