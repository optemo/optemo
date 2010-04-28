module BtxtrLabels
  def BtxtrLabels.save_combined_rules_for_all_clusters(version = nil)
    if version.nil?() then
      version = $clustermodel.maximum('version')
    end

    clusters = \
    $clustermodel.find(:all, :conditions = { :version => version })

    clusters.map{ |c|
      combined_rules.save_combined_rules_for_cluster(c)
    }
  end
end
