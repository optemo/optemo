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
end