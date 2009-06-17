class PrintersController < ProductsController
  before_filter :pickProduct
  
  def pickProduct
    session[:productType] = 'Printer'

  end
end
