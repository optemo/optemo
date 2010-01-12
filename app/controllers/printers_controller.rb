class PrintersController < ProductsController
  before_filter :pickProduct
  
  def pickProduct

    session[:productType] = 'Printer'
    @@session.update_attribute('product_type', 'Printer') if @@session.product_type.nil? || @@session.product_type != 'Printer'
    $model = Printer
    $nodemodel = PrinterNode
    $clustermodel = PrinterCluster
    $featuremodel = PrinterFeatures
  end
end
