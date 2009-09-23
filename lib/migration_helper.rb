module MigrationHelper
  def addBasicProductFeatures(t)
    
    t.text    :title
    
    t.integer :price
    t.string  :pricestr
    t.boolean :iseligibleforsupersavershipping
    t.integer :bestoffer
    t.string  :pricehistory
    
    t.string  :imagesurl
    t.integer :imagesheight
    t.integer :imageswidth
    t.string  :imagemurl
    t.integer :imagemheight
    t.integer :imagemwidth 
    t.string  :imagelurl 
    t.integer :imagelheight   
    t.integer :imagelwidth
    
    t.boolean :instock
    t.float   :averagereviewrating
    t.integer :totalreviews
    t.timestamps
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
  
  def  addPrinterTableProperties(t)
    addBasicProductFeatures(t)
    addDimensions(t)
    
    t.string :brand
    t.float :displaysize
    t.string :ean
    t.text :feature
    t.integer :listpriceint #rename to listprice
    t.string :model
    
    t.string :mpn
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
    
    t.string :manufacturerproducturl
  end
  def linkToProductAndRetailer(t)
  
    t.integer :product_id
    t.integer :retailer_id
    t.string  :local_id
  end
  def removeBasicProductFeatures
    
  end
end