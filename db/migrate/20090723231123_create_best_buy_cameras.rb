class CreateBestBuyCameras < ActiveRecord::Migration
  def self.up
    create_table :best_buy_cameras do |t|

      t.timestamps
      
      t.primary_key :id
      
      t.text      :label 
      t.text      :detailpageurl 
      t.text      :imageurl
      t.text      :glossary
            
      t.string :viewfindertype # TODO
      
      t.boolean :waterproof
      t.boolean :slr
      
     t.string      :mpn
     t.string      :brand
     t.string      :model
     # 
     t.float       :displaysize
     # 
     t.string      :listpricestr
     t.integer     :listpriceint
     # 
     t.float       :opticalzoom 
     t.float       :digitalzoom
     # 
     t.float       :maximumresolution
     # 
     #  # I might have this somewhere...
     # t.boolean     :batteriesincluded
     t.string      :batterydescription
     # t.string      :binding
     # t.string      :connectivity
     # t.string      :ean
     # t.text        :feature
     t.boolean     :hasredeyereduction
     # t.string      :includedsoftware
      t.float     :itemheight
      t.float     :itemlength
      t.float     :itemwidth
      t.float     :itemweight
     # t.float       :maximumfocallength
     # t.float       :minimumfocallength
     # t.integer     :packageheight 
     # t.integer     :packagelength
     # t.integer     :packagewidth
     # t.integer     :packageweight 
     # t.date        :releasedate
     # t.text        :specialfeatures
    end
  end

  def self.down
    drop_table :best_buy_cameras
  end
end
