class CreateBestBuyCameras < ActiveRecord::Migration
  def self.up
    create_table :best_buy_cameras do |t|

      t.timestamps
      
      t.primary_key :id
      
      # IDs etc from BestBuy
      t.string      :category
      t.string      :categoryid
      t.string      :catgroup
      t.string      :catsubclass
      t.string      :fsskuid
      t.string      :skuid
      t.string      :guid
      
      t.string      :label 
      t.text        :detailpageurl 
      t.text        :imageurl
      
      t.string      :depth
      t.string      :description
      t.string      :digitalzoom
      t.string      :dimensionsdepth
      t.string      :dimensionsheight
      t.string      :dimensionswidth
      t.string      :framerate1024x768resolution
      t.string      :framerate160x120resolution
      t.string      :framerate320x240resolution
      t.string      :framerate640x480resolution
      t.string      :framerate800x600resolution
      t.string      :framerateotherresolutions

      t.string :glossary
      t.string :height
      
      t.string :includedbatterymodel
      
      t.string :lcdmonitor
      t.string :lcdmonitorresolution
      t.string :lcdresolution
      t.string :lcdsize
      t.string :link
      
      t.string :longdescription
      
      t.string :manufacturer
      
      t.string :megapixels
      
      
      t.string :modelnumber
      
      t.string :opticalzoom      
      
      t.string :price
      
      t.string :redeyereductionflashmode
      t.string :redeyeremoval
      
      t.string :resolutionhighestqualitymode
      t.string :resolutionlowestqualitymode
      t.string :resolutionmediumqualitymode
      
      t.string :saleenddate
      t.string :saleprice
      
      t.string :savings
      
      
      t.string :totalpixels
      t.string :viewfindertype
      t.string :webcode
      t.string :weight
      t.string :weightwithbatteries
      t.string :width
      
     # # IMPORTANT!
     # 
     t.string      :mpn
     # t.string      :brand
     # t.string      :model
     # 
     # t.float       :displaysize
     # 
     # t.string      :listpricestr
     # t.integer     :listpriceint
     # 
     # t.float       :opticalzoom 
     # t.float       :digitalzoom
     # 
     # t.float       :maximumresolution
     # 
     #  # I might have this somewhere...
     # t.boolean     :batteriesincluded
     # t.string      :batterydescription
     # t.string      :binding
     # t.string      :connectivity
     # t.string      :ean
     # t.text        :feature
     # t.boolean     :hasredeyereduction
     # t.string      :includedsoftware
     # t.integer     :itemheight
     # t.integer     :itemlength
     # t.integer     :itemwidth
     # t.integer     :itemweight
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
