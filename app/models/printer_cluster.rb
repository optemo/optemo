require 'cluster'
class PrinterCluster < ActiveRecord::Base
  include Cluster
end
