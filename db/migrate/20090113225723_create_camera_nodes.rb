class CreateCameraNodes < ActiveRecord::Migration
  def self.up
    create_table :camera_nodes do |t|
      t.primary_key :id
      t.integer :cluster_id
      t.integer :product_id
      Camera::ContinuousFeaturesF.each do |name|
        t.float name.intern
      end
      Camera::CategoricalFeaturesF.each do |name|
        t.string name.intern
      end
      Camera::BinaryFeaturesF.each do |name|
        t.boolean name.intern
      end
      t.float :utility
      t.string :region
      t.integer :version
    end
    add_index :camera_nodes, :product_id
    add_index :camera_nodes, :cluster_id
  end

  def self.down
    drop_table :camera_nodes
  end
end
