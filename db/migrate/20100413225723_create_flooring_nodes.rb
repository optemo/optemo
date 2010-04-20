class CreateFlooringNodes < ActiveRecord::Migration
  def self.up
    create_table :flooring_nodes do |t|
      t.primary_key :id
      t.integer :cluster_id
      t.integer :product_id
      Flooring::ContinuousFeaturesF.each do |name|
        t.float name.intern
      end
      Flooring::CategoricalFeaturesF.each do |name|
        t.string name.intern
      end
      Flooring::BinaryFeaturesF.each do |name|
        t.boolean name.intern
      end
      t.float :utility
      t.string :region
      t.integer :version
    end
    add_index :flooring_nodes, :product_id
    add_index :flooring_nodes, :cluster_id
  end

  def self.down
    drop_table :flooring_nodes
  end
end
