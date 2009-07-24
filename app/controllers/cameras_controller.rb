class CamerasController < ProductsController
  before_filter :pickProduct
  
  def pickProduct
    
    session[:productType] = 'Camera'
    @@session[:productType] = 'Camera'
    @@session.update_attribute('product_type', 'Camera') if @@session.product_type.nil? || @@session.product_type != 'Camera'
    $model = Camera
    $nodemodel = CameraNode
    $clustermodel = CameraCluster
    $featuremodel = CameraFeatures
  end

end
