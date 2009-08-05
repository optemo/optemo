class CreateTigerPrinters < ActiveRecord::Migration
  def self.up
    create_table :tiger_printers do |t|

      t.timestamps
      t.primary_key :id
      t.text    :title
      
      # Standard identification
      t.string :brand
      t.string :model
      
      # Tiger-specific identification
      t.text   :tigerurl
      t.string :mpn
      t.string :upcno

      # US price stuff
      t.integer :price
      t.string  :pricestr
      t.integer :listpriceint
      t.string  :listpricestr
      t.integer :bestoffer
      t.boolean :instock
      
      # Canadian price stuff
      t.integer :price_ca
      t.string  :pricestr_ca
      t.integer :listpriceint_ca
      t.string  :listpricestr_ca
      t.boolean :instock_ca
      
      # TODO switch to using migrationhelper
      
      # IMPORTANT specs / info
      t.float   :ppm
      t.integer :paperinput
      t.integer :resolutionmax
      t.integer :itemheight
      t.integer :itemlength
      t.integer :itemwidth
      t.boolean :scanner
      t.boolean :printserver
    
      # Other specs / info
      t.integer :itemweight
      t.integer :packageheight 
      t.integer :packagelength
      t.integer :packagewidth
      t.integer :packageweight
      t.string  :warranty
      t.float   :ttp
      t.string  :resolution
      t.string  :duplex
      t.string  :connectivity
      t.string  :papersize
      t.integer :paperoutput
      t.string  :dimensions
      t.integer :dutycycle 
      t.float   :ppmcolor
      t.string  :platform
      t.boolean :colorprinter
      t.datetime :scrapedat
      
    end
  end

  def self.down
    drop_table :tiger_printers
  end
end
