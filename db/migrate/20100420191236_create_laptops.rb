class CreateLaptops < ActiveRecord::Migration
  def self.up
    create_table :laptops do |t|
      t.primary_key :id
      t.text :title
      t.integer :price
      t.string :pricestr
      t.string :brand
      t.integer :hd
      t.integer :ram
      t.float :screensize
      t.boolean :instock
      t.text :imgurl

      t.timestamps
    end
  end

  def self.down
    drop_table :laptops
  end
end
