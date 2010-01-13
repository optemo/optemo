# Get all clusters that a product is in. This should be a path from a
# leaf cluster all the way up to the root cluster.
>> CameraNode.find(:all, :conditions => "product_id=324").map{|n| CameraCluster.find(n.cluster_id).id}
=> [2, 26, 1168, 3542, 3566, 4708]
# Get parents of the clusters
>> CameraNode.find(:all, :conditions => "product_id=324").map{|n| CameraCluster.find(n.cluster_id).parent_id}
=> [0, 2, 26, 0, 3542, 3566]
>> CameraCluster.find(26).children(Session.new, nil).map{|c| c.id}
=> [1164, 1166, 1168, 1170]
>> CameraCluster.find(1168).parent_id
=> 26
>> CameraCluster.find(3542).parent_id
=> 0
>> CameraCluster.find(1168).children(Session.new, nil).map{|c| c.id}
=> []
>>
>> get_cluster_ids_for_camera(Camera.find(10))
=> [4, 48, 1226, 3544, 3588, 4766]
>> get_parent_cluster_ids(get_cluster_ids_for_camera(Camera.find(10)))
=> [0, 4, 48, 0, 3544, 3588]
>> 
