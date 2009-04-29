module MigrationHelper
  def addBasicProductFeatures
    
    t.text :title
    
    t.integer :salepriceint
    t.string :salepricestr
    t.boolean :iseligibleforsupersavershipping
    
    t.string :imagesurl
    t.integer :imagesheight
    t.integer :imageswidth
    t.string :imagemurl
    t.integer :imagemheight
    t.integer :imagemwidth 
    t.string :imagelurl 
    t.integer :imagelheight   
    t.integer :imagelwidth
      
    t.boolean :instock
    t.timestamps
  end
  
  def removeBasicProductFeatures
    
  end
end