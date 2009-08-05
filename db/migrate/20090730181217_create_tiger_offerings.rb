class CreateTigerOfferings < ActiveRecord::Migration
  def self.up
    create_table :tiger_offerings do |t|

      # Auto filled in
      t.timestamps
      t.primary_key :id
      
      # ID
      t.text     :tigerurl
      
      # MUST FILL IN:
      t.integer  :tiger_printer_id
      t.integer  :priceint
      t.string   :pricestr
      t.boolean  :toolow
      t.boolean  :stock
      t.string   :region
      t.text     :url 
      t.string   :condition
      
      # OTHER
      t.string :pricehistory
      t.datetime :priceUpdate
      t.integer :shippingCost
      t.integer :tax
      t.string :state
      t.string :availability
      t.datetime :availabilityUpdate
      t.boolean   :active
      t.datetime  :activeUpdate
      t.boolean   :freeShipping
        
    end
  end

  def self.down
    drop_table :tiger_offerings
  end
end
