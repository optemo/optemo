class CreateCameraNodes < ActiveRecord::Migration
  def self.up
    create_table :camera_nodes do |t|
      t.integer :cluster_id
      t.integer :product_id
      Camera::ContinuousFeaturesF.each do |name|
        t.float name.intern
      end
      Printer::CategoricalFeaturesF.each do |name|
        t.string name.intern
      end
      Camera::BinaryFeaturesF.each do |name|
        t.boolean name.intern
      end
      t.float :utility
      t.string :region
      t.integer :version
    end
  end

  def self.down
    drop_table :camera_nodes
  end
end
