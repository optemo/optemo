module Cluster
  def getHistory
    history = []
    currentCluster = self
    while ((c = currentCluster.parent_id) != 0)
      currentCluster = self.class.find(c)
      history << currentCluster
    end
    history
  end
  
  #The subclusters
  def children
    self.class.find_all_by_parent_id(id)
  end
  
  #The represetative product for this cluster
  def representative
    product_type = self.class.name.match(/^(.+)Cluster/)[1]
    nodeclass = product_type +'Node'
    pid = nodeclass.constantize.find(:first, :order => 'price ASC', :conditions => ['cluster_id = ?',id]).product_id
    product_type.constantize.find(pid)
  end
  
  #Description for each cluster
  def description
    
  end
end