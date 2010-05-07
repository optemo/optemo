require 'combined_rules'

module BtxtrLabels
  def BtxtrLabels.save_combined_rules_for_all_clusters(version = nil)
    if version.nil?
      c = Cluster.find_last_by_product_type($product_type)
      version = c.version unless c.nil?
    end

    Cluster.find_all_by_version_and_product_type(version,$product_type).each do |c|
      save_combined_rules_for_cluster(c)
    end
  end
end
