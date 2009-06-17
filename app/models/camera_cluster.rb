require 'cluster'
class CameraCluster < ActiveRecord::Base
  include Cluster
  has_many :camera_nodes
end
