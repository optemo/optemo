class CreateNeweggOfferings < ActiveRecord::Migration
  def self.up
    create_table :newegg_offerings do |t|
      
      t.primary_key :id

      t.timestamps
      
      t.string    :item_number  # Map to Newegg Printer
      
     # t.integer :product_id     # Do not set this!
     # t.string :product_type # printer for all of them
      
      t.integer :retailer_id  # TODO: 2 difft retailers, Newegg (id=4) 
                              # and NeweggRefurbished (id=5).
      
      t.integer :priceint    
      t.string :pricestr      
      t.boolean :toolow       
      t.datetime :priceUpdate 
      
      
      t.boolean :stock        
      t.string :availability  
      t.datetime :availabilityUpdate 
      
      
      t.string    :url          
      t.boolean   :active     
      t.datetime  :activeUpdate 
      t.boolean   :freeShipping
      
    end
  end

  def self.down
    drop_table :newegg_offerings
  end
end
