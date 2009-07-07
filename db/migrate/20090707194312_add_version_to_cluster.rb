class AddVersionToCluster < ActiveRecord::Migration
  def self.up
    add_column :printer_clusters, :version, :integer, :default => 0
    add_column :camera_clusters, :version, :integer, :default => 0
    add_column :printer_nodes, :version, :integer, :default => 0
    add_column :camera_nodes, :version, :integer, :default => 0
  end

  def self.down
  end
end
