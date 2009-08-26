class CreateOne23Cartridges < ActiveRecord::Migration
  extend MigrationHelper
  def self.up
    create_table :one23_cartridges do |t|

      t.timestamps
      t.primary_key :id
      
      t.integer   :product_id
      t.string    :brand
      t.string    :model
      t.string    :mpn
      
      t.integer   :web_id
      t.text      :detailpageurl
      
      
      # Key features
      t.string    :yieldstr
      t.integer   :yield     
      t.string    :shelflifestr
      t.integer   :shelflife
      t.string    :color        # Should be categorical -- Black, Cyan, Magenta, Yellow
      t.string    :brandnameprice
      t.integer   :brandnamepriceint
      t.text      :compatible
      
      t.string    :listprice
      t.integer   :listpriceint
      
      t.text      :imageurl
      
      t.text      :instructionsurl
      
      # Other stuff
      
      addBasicProductFeatures(t)
      addDimensions(t)
      
      t.string    :warranty
      t.text      :manufacturerproducturl
      
      t.integer   :product_id
      t.string    :product_type
      t.integer   :retailer_id
      t.string    :pricehistory
      t.string    :region
      t.string    :merchant
        
      t.string    :saleprice
      t.string    :yousave
      
      t.datetime  :priceUpdate
      t.integer   :shippingCost
      t.integer   :tax
      t.string    :state
      t.boolean   :stock
      t.boolean   :toolow
      t.string    :availability
      t.datetime  :availabilityUpdate
      t.text      :url
      t.boolean   :active
      t.datetime  :activeUpdate
      t.boolean   :freeShipping
            
      
      # More
      t.boolean   :real
      t.boolean   :ink
      t.string    :condition
            
      t.integer   :offering_id
            
      t.datetime  :scrapedat
    end
  end

  def self.down
    drop_table    :one23_cartridges
  end
end
