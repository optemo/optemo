class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.integer :cluster_id
      t.integer :camera_id
      t.float :maximumresolution
      t.float :displaysize
      t.float :opticalzoom
      t.float :price
    end
  end

  def self.down
    drop_table :nodes
  end
end
