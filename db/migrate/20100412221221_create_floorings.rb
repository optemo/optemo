class CreateFloorings < ActiveRecord::Migration
  def self.up
    create_table :floorings do |t|
      t.timestamps
      t.primary_key :id

      t.text :title

      t.text :brand
      t.text :species
      t.text :feature
      t.text :colorrange
      t.float :width
      t.integer :price
      t.string :pricestr
      t.float :regularprice
      t.integer :miniorder_sq_ft
      t.integer :miniorder
      t.text :price_unit
      t.string :warranty
      t.string :brand
      t.float :thickness
      t.text :size
      t.string :finish
      t.float :profit_margin
      t.float :overallrating
      t.string :aggregate_desc
      t.boolean :instock
    end  
  end

  def self.down
    drop_table :floorings
  end
end
