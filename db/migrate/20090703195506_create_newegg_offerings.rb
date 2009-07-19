class CreateNeweggOfferings < ActiveRecord::Migration
  def self.up
    create_table :newegg_offerings do |t|
      
      t.primary_key :id

      t.timestamps
      
      t.integer   :printer_id   # The NeweggPrinter entry it links to
      t.string    :item_number  # Item number assigned by Newegg
      
      # TODO Repetitive because NeweggPrinter (to which this links) already has these two:
      t.integer   :product_id     # matches the Printer entry id
      t.string    :product_type # printer for all of them
      
      t.integer   :offering_id  # Matches the Offering entry id
      
      t.integer   :retailer_id  # 2 difft retailers, Newegg (id=4) 
                              # and NeweggRefurbished (id=6).
      
      t.integer   :priceint    
      t.string    :pricestr      
      t.boolean   :toolow       
      t.datetime  :priceUpdate 
      
      
      t.boolean   :stock        
      t.string    :availability  
      t.datetime  :availabilityUpdate 
      
      
      t.text      :url          
      t.boolean   :active     
      t.datetime  :activeUpdate 
      t.boolean   :freeShipping
      
    end
  end

  def self.down
    drop_table    :newegg_offerings
  end
end
