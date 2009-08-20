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
  
  end
  
  def addPackageDimensions(t)
    t.integer :packageheight 
    t.integer :packagelength
    t.integer :packagewidth
    t.integer :packageweight
  
  end
  
  def removeBasicProductFeatures
    
  end
end