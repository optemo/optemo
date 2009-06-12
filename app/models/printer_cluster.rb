require 'cluster'
class PrinterCluster < ActiveRecord::Base
  include Cluster
  has_many :printer_nodes
end
