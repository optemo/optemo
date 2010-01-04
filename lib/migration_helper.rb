module MigrationHelper
  def addBasicProductFeatures(t)
    t.text    :title
    #t.text    :label
    
    addPicStuff(t)
    addPricing(t)
    addPricingCa(t)
    
    t.boolean :iseligibleforsupersavershipping
    t.integer :bestoffer

    t.float   :averagereviewrating
    t.integer :totalreviews
    t.timestamps
  end
  
  def addPricingCa(t)
    t.integer :price_ca
    t.string  :price_ca_str
    t.boolean :instock_ca
    t.boolean :bestoffer_ca
  end
  
  def addPricing(t)
    t.integer :price
    t.string  :pricestr
    t.boolean :instock
    t.boolean :bestoffer
    t.string  :pricehistory # TODO remove this?
  end
  
  def addReviews(t)
    t.float   :averagereviewrating
    t.integer :totalreviews
    t.text    :reviewtext
  end
  
  def addIdStuff(t)
    # ID fields
    t.string :brand
    t.string :model
    t.string :mpn
  end
  
  def addOfferingPriceStuff(t)
    # Pricing stuff
    t.integer :price
    t.string  :pricestr
    t.boolean :stock
    t.string  :pricehistory
  end
  
  def addPicStuff(t)
    #Pic stuff
    t.string  :imagesurl
    t.integer :imagesheight
    t.integer :imageswidth
    t.string  :imagemurl
    t.integer :imagemheight
    t.integer :imagemwidth 
    t.string  :imagelurl 
    t.integer :imagelheight   
    t.integer :imagelwidth
  end
    
  def addDimensions(t)
    addProductDimensions(t)
    addPackageDimensions(t)
  end
  
  def addProductDimensions(t)
  
    t.string :dimensions
    t.integer :itemwidth
    t.integer :itemlength
    t.integer :itemheight
    t.integer :itemweight
  end
  
  def addPackageDimensions(t)
    t.integer :packageheight 
    t.integer :packagelength
    t.integer :packagewidth
    t.integer :packageweight
  
  end
  
  def addListpriceStuff(t)
    t.string      :listpricestr
    t.integer     :listpriceint
  end
  
  def addCameraProperties(t)
    #Reqd
    t.float       :opticalzoom
    t.float       :maximumresolution
    t.string      :resolution
    t.float       :displaysize
    t.boolean     :slr
    t.boolean     :waterproof
    
    #Good info
    t.float       :maximumfocallength
    t.float       :minimumfocallength
    t.float       :digitalzoom
    
    #Quite extra
    t.boolean     :batteriesincluded
    t.string      :batterydescription
    t.string      :connectivity
    t.boolean     :hasredeyereduction
    t.string      :includedsoftware
  end
  
  def addPrinterProperties(t)
     # Reqd
     t.float :ppm
     t.string :resolution
     t.integer :resolutionmax
     t.integer :paperinput
     t.boolean :scanner
     t.boolean :printserver
     
     # Good info
     t.float :displaysize
     t.float :ttp
     t.string :duplex
     t.boolean :colorprinter
     t.boolean :fax
     t.string :papersize
     t.integer :paperoutput
     
     # Quite extra
     t.string :connectivity
     t.integer :dutycycle 
     t.string :special
     t.float :ppmcolor
     t.string :platform
  end
  
  def addPrinterTableProperties(t)
    addBasicProductFeatures(t)
    addDimensions(t)
    addIdStuff(t)
    addPrinterProperties(t)
    
    t.float :displaysize
    t.string :ean
    t.text :feature
    
    t.integer :listpriceint #rename to listprice
    
    t.string :warranty
    
    t.datetime :scrapedat
    t.boolean :nodetails
    t.boolean :bw
    
    t.string :manufacturerproducturl
  end

  def linkToProductAndRetailer(t)
    t.integer :product_id
    t.integer :retailer_id
    t.string  :local_id
    # merchant?
  end
  
  def removeBasicProductFeatures
    
  end
end