class AddVersionToCluster < ActiveRecord::Migration
  def self.up
    add_column :printer_clusters, :version, :integer
    add_column :camera_clusters, :version, :integer
    add_column :printer_nodes, :version, :integer
    add_column :camera_nodes, :version, :integer
  end

  def self.down
  end
end
