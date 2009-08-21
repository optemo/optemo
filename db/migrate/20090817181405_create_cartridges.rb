class CreateCartridges < ActiveRecord::Migration
  extend MigrationHelper
  def self.up
    create_table :cartridges do |t|
      
      t.primary_key :id
      t.string :brand
      t.string :model
      t.string :mpn
      t.string :compatiblebrand
      
      t.integer :yield     
      t.integer :shelflife
      t.string  :color        # Should be categorical -- Black, Cyan, Magenta, Yellow
      
      t.string  :brandnameprice
      t.integer :brandnamepriceint
      
      t.text    :imageurl
      
      # Other stuff
      
      addBasicProductFeatures(t)
      addDimensions(t)
      
      # More weird stuff
      t.float     :costperyield
      t.string    :condition
      t.boolean   :real
      
      
      t.string :warranty
      t.text :manufacturerproducturl
            
      t.datetime :scrapedat
      
    end
  end

  def self.down
    drop_table :cartridges
  end
end
