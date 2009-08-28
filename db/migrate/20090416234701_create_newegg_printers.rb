class CreateNeweggPrinters < ActiveRecord::Migration
  def self.up
    create_table :newegg_printers do |t|
      
      t.primary_key :id
      t.string :item_number
      
      t.string :title
      
      t.integer :product_id     # matches the Printer entry id
      t.string :product_type    # printer for all of them
      
      t.string :model
      t.string :mpn
      t.string :series   # Unique to Newegg
      t.string :brand
      
      t.integer :listpriceint
      t.string :listpricestr
      
      t.string :imageurl
      t.text :detailpageurl
      
      t.string :recommendeduse  # Unique to Newegg
      t.string :dimensions
      
      t.integer :itemheight
      t.integer :itemwidth
      t.integer :itemlength
      t.integer :itemweight # In pounds
      
      # TODO package lwh? and weight?
     
      t.boolean :colorprinter
      t.boolean :printserver
      t.boolean :scanner
      t.datetime :scrapedat
      
      t.string :lasertechnology # Unique to Newegg
      
      t.string :platform
      t.string :warranty
            
      t.float  :ppm       
      t.float  :ppmcolor
      t.float  :ttp         
      t.string :resolution 
      t.integer :resolutionmax
      
      t.string :language 
      t.string :duplex
      t.integer :dutycycle
      
      t.integer :paperinput # std in Newegg
      t.integer :paperinputmax # Unique to Newegg
      t.integer :paperoutput  # std in Newegg
      t.integer :paperoutputmax # Unique to Newegg
      
      t.string :systemmemory 
      t.string :systemmemorymax
      
      t.string :mediatype # Type of paper 
      t.string :papersize
      
      t.string :cputype
      t.float :cpuspeed  #string :processormhz
      
      t.string :connectivity
      
      t.string :special
      
      
      # --- Unique to Newegg ---- #
      
        # Ports
      t.string :usbports  
      t.string :lptports
      t.string :networkports
      t.string :otherports
      t.string :comports
      
        # Copier stuff
      t.string :copyspeedblack
      t.string :copyspeedcolor
      t.string :copyqualityblack
      t.string :copyqualitycolor
      t.string :maxnumberofcopies
      
        # Scanner stuff
      t.string :scanresolutionenhanced
      t.string :maxdocumentenlargement
      t.string :maxdocumentreduction
      t.string :scancolordepth
      t.string :scanresolutionoptical
      t.string :scanresolutionhardware
      t.string :scanelement
      
        # Fax stuff
      t.string :faxfeatures
      t.string :faxmemory
      t.string :faxtransmissionspeed
      t.string :colorfax
      t.string :faxresolutions
      
        # Other
      t.string :noiselevelapprox
      t.string :modemspeed
      t.string :emulations
      t.string :display
      t.string :packagecontents
      t.string :softwareincluded
      t.string :borderlessphotosizes
      t.string :colorresolution
      t.string :papertraysstd 
      t.string :papertraysmax
      
      t.string :cartridgescompatible 
      t.string :powerrequirements 
      t.string :powerconsumption
    end
  end

  def self.down
    drop_table :newegg_printers
  end
end
