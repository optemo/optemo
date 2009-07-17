class CreateTigerPrinters < ActiveRecord::Migration
  def self.up
    create_table :tiger_printers do |t|

      t.timestamps
      t.primary_key :id
      t.string :tigerurl
      
      t.text    :title

      t.integer :price
      t.string  :pricestr
      t.boolean :instock
      
      t.string :brand
      t.string :model
      
      t.string :mfgpartno
      t.string :upcno
    
      t.string :availability
       
      t.integer :itemheight
      t.integer :itemlength
      t.integer :itemwidth
      t.integer :itemweight
      t.integer :listpriceint
      t.integer :packageheight 
      t.integer :packagelength
      t.integer :packagewidth
      t.integer :packageweight
      t.string  :warranty
      
      t.float :ppm
      t.float :ttp
      t.string :resolution
      t.integer :resolutionmax
      t.string :duplex
      t.string :connectivity
      t.string :papersize
      t.integer :paperoutput
      t.string :dimensions
      t.integer :dutycycle 
      t.integer :paperinput
      t.string :special
      t.float :ppmcolor
      t.string :platform
      t.boolean :colorprinter
      t.boolean :scanner
      t.datetime :scrapedat
      t.boolean :nodetails
      t.boolean :printserver
      
    end
  end

  def self.down
    drop_table :tiger_printers
  end
end
