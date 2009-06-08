class CreateRetailerOfferings < ActiveRecord::Migration
  def self.up
    create_table :retailer_offerings do |t|
      t.integer :product_id
      t.string :product_type
      t.integer :retailer_id
      t.string :pricehistory
      t.string :merchant
      
      t.integer :priceint
      t.string :pricestr
      t.datetime :priceUpdate
      t.integer :shippingCost
      t.integer :tax
      t.string :state
      t.boolean :stock
      t.boolean :toolow
      t.string :availability
      t.datetime :availabilityUpdate
      t.boolean :iseligibleforsupersavershipping
      t.string :url
      t.boolean   :active
      t.datetime  :activeUpdate
      t.boolean   :freeShipping
  
      t.timestamps
    end
  end

  def self.down
    drop_table :retailer_offerings
  end
end
