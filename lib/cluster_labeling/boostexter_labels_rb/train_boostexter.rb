require 'training'

module BtxtrLabels
  def BtxtrLabels.train_boostexter_on_all_clusters(version = nil)
    if version.nil?
      c = Cluster.find_last_by_product_type(Session.current.product_type)
      version = c.version unless c.nil?
    end

    Cluster.find_all_by_version_and_product_type(version, Session.current.product_type).each do |c|
      generate_names_file(c)
      generate_data_file(c)
      train_boostexter(c)
    end
  end
end
