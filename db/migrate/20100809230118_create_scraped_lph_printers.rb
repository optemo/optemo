class CreateScrapedLphPrinters < ActiveRecord::Migration
  def self.up
    extend MigrationHelper
    create_table :scraped_lph_printers do |t|

      t.primary_key :id
      
      addPrinterTableProperties(t)
      
      linkToProductAndRetailer(t)
      
      t.text :imageurl
      
    end
  end

  def self.down
    drop_table :scraped_lph_printers
  end
end
