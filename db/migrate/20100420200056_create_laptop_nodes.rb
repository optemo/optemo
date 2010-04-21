class CreateLaptopNodes < ActiveRecord::Migration
  def self.up
    create_table :laptop_nodes do |t|
      t.primary_key :id
      t.integer :cluster_id
      t.integer :product_id
      Laptop::ContinuousFeaturesF.each do |name|
        t.float name.intern
      end
      Laptop::CategoricalFeaturesF.each do |name|
        t.string name.intern
      end
      Laptop::BinaryFeaturesF.each do |name|
        t.boolean name.intern
      end
      t.float :utility
      t.string :region
      t.integer :version
    end
    add_index :laptop_nodes, :product_id
    add_index :laptop_nodes, :cluster_id
  end

  def self.down
    drop_table :laptop_nodes
  end
end
