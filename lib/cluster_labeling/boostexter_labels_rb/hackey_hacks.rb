# Hackey hacks!
$DefaultProduct = nil
$model = nil
$nodemodel = nil
$clustermodel = nil
$featuremodel = nil

module BtxtrLabels
  def BtxtrLabels.set_product_type(product_type)
    $DefaultProduct = product_type
    $model = product_type
    
    $nodemodel = Kernel.const_get(product_type.to_s() + "Node")
    $clustermodel = Kernel.const_get(product_type.to_s() + "Cluster")
    $featuremodel = Kernel.const_get(product_type.to_s() + "Features")
  end
end
