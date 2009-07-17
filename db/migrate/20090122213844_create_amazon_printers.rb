require 'migration_helper'
class CreateAmazonPrinters < ActiveRecord::Migration
  extend MigrationHelper
  def self.up
    create_table :amazon_printers do |t|
      addBasicProductFeatures(t)
      t.primary_key :id
      t.string :asin
      t.text :detailpageurl
      t.string :binding
      t.string :brand
      t.string :color
      t.string :cpumanufacturer
      t.float :cpuspeed
      t.string :cputype
      t.float :displaysize
      t.string :ean
      t.text :feature
      t.string :graphicsmemorysize
      t.boolean :isautographed
      t.boolean :ismemorabilia
      t.integer :itemheight
      t.integer :itemlength
      t.integer :itemwidth
      t.integer :itemweight
      t.string :label
      t.string :language
      t.string :legaldisclaimer
      t.string :listpricestr
      t.integer :listpriceint
      t.string :manufacturer
      t.string :model
      t.string :modemdescription
      t.string :mpn
      t.string :nativeresolution
      t.integer :numberofitems
      t.integer :packageheight 
      t.integer :packagelength
      t.integer :packagewidth
      t.integer :packageweight
      t.integer :processorcount 
      t.string :productgroup
      t.string :publisher
      t.text :specialfeatures
      t.string :studio
      t.integer :systemmemorysize
      t.string :systemmemorytype
      t.string :warranty
      
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
      t.integer :resolutionarea
      
      t.integer :product_id
      t.string :product_type, :default => 'Printer'
    end
  end

  def self.down
    drop_table :amazon_printers
  end
end
