require 'migration_helper'
class CreateRetailerOfferings < ActiveRecord::Migration
  def self.up
    extend MigrationHelper
    
    create_table :retailer_offerings do |t|
      t.integer :product_id
      t.string :product_type
      t.string :pricehistory
      t.string :region
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
      t.text :url
      t.boolean   :active
      t.datetime  :activeUpdate
      t.boolean   :freeShipping
  
      t.timestamps
      
      linkToProductAndRetailer(t)
    end
  end

  def self.down
    drop_table :retailer_offerings
  end
end
