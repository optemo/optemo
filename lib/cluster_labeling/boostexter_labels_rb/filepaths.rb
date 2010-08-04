module BtxtrLabels
  Output_subdir = "#{RAILS_ROOT}/lib/cluster_labeling/cc_boostexter_files"
  Boostexter_subdir = "#{RAILS_ROOT}/lib/cluster_labeling/BoosTexter2_1"

  def BtxtrLabels.get_filename_stem(cluster)
    return Output_subdir + "/" + Session.current.product_type + "_" + cluster.id.to_s()
  end

  def BtxtrLabels.get_names_filename(cluster)
    filestem = get_filename_stem(cluster)
    return filestem + ".names"
  end

  def BtxtrLabels.get_data_filename(cluster)
    filestem = get_filename_stem(cluster)
    return filestem + ".data"
  end

  def BtxtrLabels.get_strong_hypothesis_filename(cluster)
    filestem = get_filename_stem(cluster)
    return filestem + ".shyp"
  end
end
