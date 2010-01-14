# Hackey hacks!
$DefaultProduct = Camera
$model = Camera
$nodemodel = CameraNode
$clustermodel = CameraCluster
$featuremodel = CameraFeatures

# Getting cluster children (Why does this depend on a user session?)
# This depends on user session because the user session contains query
# filters and these filters are applied before retrieving a list of
# nodes. The second parameter is the searchpids. If there are no
# searchpids, then nothing is filtered. Look at Cluster::nodes.
def get_cluster_children(cluster)
  cluster.children(Session.new, nil)
end

# Getting cluster parent
def get_cluster_parent(cluster)
  $clustermodel.find(cluster.parent_id)
end
def get_parent_cluster_ids(cluster_ids)
  $clustermodel.find(cluster_ids).map{ |c| c.parent_id }
end

# # Why is a particular user's session being assigned to a global variable?
#     mysession = Session.find_by_id(session[:user_id])
#     if mysession.nil?
#       mysession = Session.new
#       mysession.ip = request.remote_ip
#       mysession.save
#       # Create a row in every product-features table
#       $ProdTypeList.each do |p|
#         myProduct = (p + 'Features').constantize.new
#         myProduct.session_id = mysession.id        
#         myProduct.save
#       end
#       session[:user_id] = mysession.id
#       @@session = mysession      
#     else
#       @@session = mysession
#     end

# Getting cameras in a cluster - need to get the nodes in the cluster
# and then find cameras that correspond to nodes. This allows cameras
# to belong to multiple clusters (I think?).
def get_item_ids_in_cluster(cluster)
  nodes = cluster.nodes(Session.new, nil)
  nodes.map{ |n| n.product_id }
end

def get_items(item_ids, throw_if_not_found = nil)
  if throw_if_not_found
    $model.find(:id, item_ids)
  else
    $model.find(:all, :conditions => { :id => item_ids })
  end
end

require 'set'

def find_missing_items(item_ids)
  found_item_ids = get_items(item_ids).map{ |c| c.id }
  (Set.new(item_ids) - Set.new(found_item_ids)).to_a
end

def get_latest_cluster_version()
  $clustermodel.maximum('version')
end

# Getting the clusters that a camera belongs to. This should be a path
# from a singleton leaf cluster all the way up to the root cluster.
def get_cluster_ids_for_item(item, cluster_version = get_latest_cluster_version())
  conditions = { :product_id => item.id, :version => cluster_version }
  nodes = $nodemodel.find(:all, :conditions => conditions)
  cluster_ids= nodes.map{ |n| n.cluster_id }
  cluster_ids
end

# Getting reviews
def get_reviews_for_item(item)
  Review.find(:all, :conditions => { :product_id => item.id })
end
