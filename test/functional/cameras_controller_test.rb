require 'test_helper'

class CamerasControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:cameras)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_camera
    assert_difference('Camera.count') do
      post :create, :camera => { }
    end

    assert_redirected_to camera_path(assigns(:camera))
  end

  def test_should_show_camera
    get :show, :id => cameras(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => cameras(:one).id
    assert_response :success
  end

  def test_should_update_camera
    put :update, :id => cameras(:one).id, :camera => { }
    assert_redirected_to camera_path(assigns(:camera))
  end

  def test_should_destroy_camera
    assert_difference('Camera.count', -1) do
      delete :destroy, :id => cameras(:one).id
    end

    assert_redirected_to cameras_path
  end
end
