class CreateClusters < ActiveRecord::Migration
  def self.up
    create_table :clusters do |t|
      t.primary_key :id
      t.integer :parent_id
      t.integer :layer
      t.integer :cluster_size
      t.float :maximumresolution_max, :maximumresolution_min
      t.float :displaysize_max, :displaysize_min
      t.float :opticalzoom_max, :opticalzoom_min
      t.float :price_max, :price_min
    end
  end

  def self.down
    drop_table :clusters
  end
end
