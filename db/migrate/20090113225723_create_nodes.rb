class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.integer :cluster_id
      t.integer :product_id
      DbProperty.find_by_name('Camera').db_features.each do |f|
        t.float f.name.intern
      end
      t.float :price
      t.string :brand
    end
  end

  def self.down
    drop_table :nodes
  end
end
