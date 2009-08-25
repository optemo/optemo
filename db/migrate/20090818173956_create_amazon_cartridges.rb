class CreateAmazonCartridges < ActiveRecord::Migration
  extend MigrationHelper
  def self.up
    create_table :amazon_cartridges do |t|

      t.timestamps
      
      t.primary_key :id
      
      t.string    :brand
      t.string    :model
      t.string    :mpn
      t.string    :asin
      t.integer   :product_id
      
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
      
      # Other stuff
      
      addBasicProductFeatures(t)
      addDimensions(t)
      
      t.string    :warranty
      t.text      :manufacturerproducturl
      
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
      t.boolean   :iseligibleforsupersavershipping
      t.text      :url
      t.boolean   :active
      t.datetime  :activeUpdate
      t.boolean   :freeShipping
      
      t.boolean   :real
      t.boolean   :toner
      t.string    :condition
      t.string    :realbrand
      t.string    :compatiblebrand
      
      t.integer   :offering_id
      
      t.integer   :numberofitems
      t.text      :specialfeatures
            
      t.datetime  :scrapedat
    end
  end

  def self.down
    drop_table :amazon_cartridges
  end
end
