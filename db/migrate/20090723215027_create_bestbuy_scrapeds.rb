class CreateBestbuyScrapeds < ActiveRecord::Migration
  def self.up
    create_table :bestbuy_scrapeds do |t|

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

       t.text      :label 
       t.text        :detailpageurl 
       t.text        :imageurl
       t.text      :glossary

       t.text      :description

       t.string :includedbatterymodel

       t.text     :longdescription

       t.string :redeyereductionflashmode
       t.string :redeyeremoval

       t.string :resolutionhighestqualitymode
       t.string :resolutionlowestqualitymode
       t.string :resolutionmediumqualitymode

       t.string :saleenddate
       t.string :saleprice
       t.string :savings

       t.string :viewfindertype
       t.string :webcode

      # # IMPORTANT!
      # 
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
      # t.string      :batterydescription
      # t.string      :binding
      # t.string      :connectivity
      # t.string      :ean
      # t.text        :feature
      # t.boolean     :hasredeyereduction
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
    drop_table :bestbuy_scrapeds
  end
end
