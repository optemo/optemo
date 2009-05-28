class PrinterCluster < ActiveRecord::Base
  def getHistory
    history = []
    currentCluster = self
    while ((c = currentCluster.parent_id) != 0)
      currentCluster = PrinterCluster.find(c)
      history << currentCluster
    end
    history
  end
end
