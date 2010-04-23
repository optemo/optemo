#!/usr/bin/env irb
require 'training'

module BtxtrLabels
  def BtxtrLabels.train_boostexter_on_all_clusters(version = nil)
    if version.nil?() then
      version = $clustermodel.maximum('version')
    end

    clusters = \
    $clustermodel.find(:all, :conditions => { :version => version })
  
    clusters.map{ |c|
      generate_names_file(c)
      generate_data_file(c)
      train_boostexter(c)
    }
  end
end
