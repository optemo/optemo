class AddRealFeaturesToPrinter < ActiveRecord::Migration
  def self.up
    add_column :printers, :ppm, :float
    add_column :printers, :ttp, :float
    add_column :printers, :resolution, :string
    add_column :printers, :duplex       ,:string
    add_column :printers, :connectivity ,:string
    add_column :printers, :papersize    ,:string
    add_column :printers, :paperoutput  ,:integer
    add_column :printers, :dimensions   ,:string
    add_column :printers, :dutycycle    ,:integer
    add_column :printers, :paperinput   ,:integer
    add_column :printers, :special      ,:string
    add_column :printers, :ppmcolor     ,:float
    add_column :printers, :platform     ,:string
    add_column :printers, :colorprinter ,:boolean
    add_column :printers, :scanner      ,:boolean
    add_column :printers, :scrapedat    ,:datetime
    add_column :printers, :nodetails    ,:boolean
    add_column :printers, :printserver  ,:boolean
  end

  def self.down
    remove_column :printers, :ppm
    remove_column :printers, :ttp
    remove_column :printers, :resolution
    remove_column :printers, :duplex       
    remove_column :printers, :connectivity 
    remove_column :printers, :papersize    
    remove_column :printers, :paperoutput  
    remove_column :printers, :dimensions   
    remove_column :printers, :dutycycle    
    remove_column :printers, :paperinput   
    remove_column :printers, :special     
    remove_column :printers, :ppmcolor   
    remove_column :printers, :platform    
    remove_column :printers, :colorprinter   
    remove_column :printers, :scanner
    remove_column :printers, :scrapedat
    remove_column :printers, :nodetails
    remove_column :printers, :printserver
  end
end
