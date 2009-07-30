class CreateTigerScrapeds < ActiveRecord::Migration
  def self.up
    create_table :tiger_scrapeds do |t|

      t.timestamps
      
       t.string :tigerurl # The relative url that gets you the detail page. use as id for now
      
      # REgional
       t.string :region
      
       # Yellow Box
       t.string :manufacturedby
       t.string :warrantyprovidedby
       t.string :shippingweight
       t.string :mfgpartno
       t.string :upcno
       t.string :boxsize
       t.string :availability
       t.string :itmdets
       
       # Prices
       t.string :finalprice
       t.string :instantsavings
       t.string :originalprice
       t.string :price
      
       # Specs
       t.string :allinone
       t.string :approximatepageyield
       t.string :automaticfeeder
       t.string :color
       t.string :coloroutput
       t.string :condition
       t.string :connectivity
       t.string :dimensions
       t.string :duplexprinting
       t.string :faxcapability
       t.string :firstpageoutputtime
       t.string :maximumdutycycle
       t.string :memoryincluded
       t.string :networkready
       t.string :optionalconnectivity
       t.string :optionalpaperinput
       t.string :papersizessupported
       t.string :powersource
       t.string :powersupply
       t.string :printeruse
       t.string :printmethod
       t.string :printspeed
       t.string :printspeedbw
       t.string :printspeedcolor
       t.string :printtechnology
       t.string :processor
       t.string :producttype
       t.string :protocols
       t.string :quantity
       t.string :resolution
       t.string :specialfeatures
       t.string :standardpaperinput
       t.string :standardpaperoutput
       t.string :transferrate
       t.string :wireless
    end
  end

  def self.down
    drop_table :tiger_scrapeds
  end
end
