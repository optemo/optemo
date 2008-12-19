class CreateCameras < ActiveRecord::Migration
  def self.up
    create_table :cameras do |t|
      t.primary_key :id
      t.string :asin
      t.text :detailpageurl
      t.boolean :batteriesincluded
      t.string :batterydescription
      t.string :binding
      t.string :brand
      t.string :connectivity
      t.float :digitalzoom
      t.float :displaysize
      t.string :ean
      t.text :feature
      t.string :floppydiskdrivedescription
      t.boolean :hasredeyereduction
      t.string :includedsoftware
      t.boolean :isautographed
      t.boolean :ismemorabilia
      t.integer :itemheight
      t.integer :itemlength
      t.integer :itemwidth
      t.integer :itemweight
      t.string :label
      t.string :listpricestr
      t.integer :listpriceint
      t.string :manufacturer
      t.float :maximumfocallength
      t.float :maximumresolution
      t.float :minimumfocallength
      t.string :model
      t.string :mpn
      t.float :opticalzoom 
      t.integer :packageheight 
      t.integer :packagelength
      t.integer :packagewidth
      t.integer :packageweight 
      t.string :productgroup
      t.string :publisher
      t.date :releasedate
      t.text :specialfeatures
      t.string :studio
      t.text :title
      t.integer :upc

      t.string :merchant
      t.string :condition
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
      t.timestamps
    end  
  end

  def self.down
    drop_table :cameras
  end
end
