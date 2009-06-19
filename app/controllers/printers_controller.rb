class PrintersController < ProductsController
  before_filter :pickProduct
  
  def pickProduct
    session[:productType] = 'Printer'
    s = Session.find(session[:user_id])
    s.update_attribute('product_type', 'Printer') if s.product_type.nil? || s.product_type != 'Printer'
    $model = Printer
    $nodemodel = PrinterNode
    $clustermodel = PrinterCluster
  end
end