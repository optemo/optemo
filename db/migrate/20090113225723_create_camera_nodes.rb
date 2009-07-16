class CreateCameraNodes < ActiveRecord::Migration
  def self.up
    create_table :camera_nodes do |t|
      t.integer :cluster_id
      t.integer :product_id
      DbProperty.find_by_name('Camera').db_features.each do |f|
        t.float f.name.intern
      end
      t.float :price
      t.string :brand
      t.float :utility
    end
  end

  def self.down
    drop_table :camera_nodes
  end
end
