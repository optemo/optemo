require 'migration_helper'
class CreatePrinters < ActiveRecord::Migration
  extend MigrationHelper
  def self.up
    create_table :printers do |t|
      addBasicProductFeatures(t)
      t.primary_key :id
      t.string :brand
      t.float :displaysize
      t.string :ean
      t.text :feature
      t.integer :itemheight
      t.integer :itemlength
      t.integer :itemwidth
      t.integer :itemweight
      t.integer :listpriceint #rename to listprice
      t.string :model
      t.string :mpn
      t.integer :packageheight 
      t.integer :packagelength
      t.integer :packagewidth
      t.integer :packageweight
      t.string :warranty
      t.string :manufacturerproducturl
      
      t.float :ppm
      t.float :ttp
      t.string :resolution
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
      t.integer :resolutionmax
      t.boolean :fax
      t.boolean :bw
      
      t.string :manufacturerproducturl
    end
  end

  def self.down
    drop_table :printers
  end
end
