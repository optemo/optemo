class CamerasController < ProductsController
  before_filter :pickProduct
  
  def pickProduct
    session[:productType] = 'Camera'
  end
end
