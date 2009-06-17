class CamerasController < ProductsController
  before_filter :pickProduct
  
  def pickProduct
    session[:productType] = 'Camera'
    s = Session.find(session[:user_id])
    s.update_attribute('product_type', 'Camera') if s.product_type.nil? || s.product_type != 'Camera'
  end
end
