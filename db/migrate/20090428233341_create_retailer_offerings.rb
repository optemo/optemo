class CreateRetailerOfferings < ActiveRecord::Migration
  def self.up
    create_table :retailer_offerings do |t|
      t.integer :product_id
      t.string :product_type
      t.integer :priceint
      t.string :pricestr
      t.integer :shipping
      t.integer :tax
      t.string :state
      t.string :link
      t.integer :retailer_id
      t.boolean :stock
      t.string :pricehistory
      t.boolean :toolow
      t.string :availability
      t.boolean :iseligibleforsupersavershipping
      t.string :merchant
      t.string :url
  
      t.timestamps
    end
  end

  def self.down
    drop_table :retailer_offerings
  end
end
