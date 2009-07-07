class CreateNeweggPrinterScrapedDatas < ActiveRecord::Migration
  def self.up
    create_table :newegg_printer_scraped_datas do |t|

      t.timestamps
      
      t.primary_key :id
      t.string :item_number
      
      t.string :manufacturer
      t.string :series
      t.string :brand
      
      t.boolean :toolow
      t.float :saleprice
      t.float :listprice
      t.string :imageurl
       
      t.string :model
      t.string :recommendeduse  
      t.string :dimensions
      t.integer :weight # In pounds.
      
      t.string :outputtype # Color or monochrome
      t.string :lasertechnology # Laser or (not sure what)
      
      t.float  :blackprintspeed     # ppm  
      t.float  :colorprintspeed     # ppmcolor
      t.float  :timetofirstpageseconds      # ttp    
      t.string :blackprintquality # resolution
      t.string :colorprintquality  
      
      t.string :printlanguagesstd
      t.string :duplexprinting # duplex
      t.integer :maxdutycycle # dutycycle
      
      t.string :papertraysstd
      t.string :papertraysmax
      t.integer :inputcapacitystd # paperinput
      t.integer :inputcapacitymax
      t.integer :outputcapacitystd # paperoutput
      t.integer :outputcapacitymax
      
      t.string :mediatype # Type of paper 
      t.string :mediasizessupported # papersize
      
      t.string :usbports
      t.string :lptports
      t.string :networkports
      t.string :otherports
      t.string :microprocessortype
      t.string :processormhz
      t.string :memorystd
      t.string :memorymax
      t.string :cartridgescompatible
      t.string :powerrequirements
      t.string :powerconsumption
      
      t.string :windowscompatible
      t.string :macintoshcompatible
      t.string :parts
      t.string :labor
      
      # Rare fields
      t.string :copyqualityblack
      t.string :scanresolutionenhanced
      t.string :windowsvista
      t.string :other
      t.string :faxfeatures
      t.string :noiselevelapprox
      t.string :modemspeed
      t.string :emulations
      t.string :comports
      t.string :display
      t.string :copyspeedblack
      t.string :maxdocumentenlargement
      t.string :maxdocumentreduction
      t.string :maxnumberofcopies
      t.string :scancolordepth
      t.string :scanresolutionoptical
      t.string :packagecontents
      t.string :faxmemory
      t.string :copyspeedcolor
      t.string :faxtransmissionspeed
      t.string :scanelement
      t.string :faxresolutions
      t.string :softwareincluded
      t.string :connectivitytechnology # connectivity (?)
      t.string :colorfax
      t.string :copyqualitycolor
      t.string :borderlessphotosizes
      t.string :scanresolutionhardware
    end
  end

  def self.down
    drop_table :newegg_printer_scraped_datas
  end
end
