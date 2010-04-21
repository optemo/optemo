require 'cluster'
class FlooringCluster < ActiveRecord::Base
  include Cluster
end
