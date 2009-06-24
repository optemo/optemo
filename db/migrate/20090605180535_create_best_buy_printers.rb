class CreateBestBuyPrinters < ActiveRecord::Migration
  def self.up
    create_table :best_buy_printers do |t|
      #BBProductOffering
      t.string    :bb_class
      t.integer   :classId
      t.string    :subclass
      t.integer   :subclassId
      t.integer   :productId
      t.string    :department
      t.integer   :departmentId
      t.string    :type
      t.string    :categoryPath
      t.string    :addToCartUrl
      t.string    :affiliateUrl
      t.string    :affiliateAddToCartUrl
      t.string    :mobileUrl
      t.string    :url
      t.string    :cjAffiliateUrl
      t.string    :cjAffiliateAddToCartUrl
      t.string    :sku
      t.string    :warrantyParts
      t.string    :warrantyLabor
      t.boolean   :bb_new
      t.boolean   :nationalFeatured
      t.boolean   :navigability
      t.datetime  :releaseDate
      t.datetime  :startDate
      t.datetime  :itemUpdateDate
      t.string    :source #Always equal to bestbuy

      #Price and Availability
      t.boolean   :active
      t.string    :activeUpdateDate
      t.boolean   :printOnly #not used
      t.boolean   :inStoreAvailability #not used
      t.string    :inStoreAvailabilityText #not used
      t.datetime  :inStoreAvailabilityUpdateDate #not used
      t.boolean   :onlineAvailability #=> stock
      t.string    :onlineAvailabilityText #=> availability
      t.datetime  :onlineAvailabilityUpdateDate #=> availabilityUpdate
      t.float     :regularPrice #not used
      t.float     :salePrice #=> priceint | pricestr
      t.datetime  :priceUpdateDate #=> priceUpdate
      t.string    :dollarSavings #not used
      t.float     :shippingCost
      t.boolean   :freeShipping
      t.string    :specialOrder #not used
      t.string    :orderable #not used
      
      #Product Specific Features
      t.string    :accessoriesImage
      t.string    :angleImage
      t.string    :remoteControlImage
      t.string    :alternateViewsImage
      t.string    :leftViewImage
      t.string    :rightViewImage
      t.string    :backViewImage
      t.string    :topViewImage
      t.string    :largeFrontImage
      t.string    :thumbnailImage
      t.string    :image
      t.string    :mediumImage
      t.string    :largeImage
      t.string    :energyGuideImage
      
      t.string    :name
      t.string    :upc
      t.string    :color #Useless
      t.string    :modelNumber
      t.string    :description
      t.string    :shortDescription
      t.text      :longDescription
      t.string    :manufacturer
      t.string    :weight
      t.float     :width
      t.float     :height
      t.float     :depth
      t.float     :shippingWeight
      t.string    :format #Seems to be an empty value
      
      t.integer   :customerReviewCount
      t.float     :customerReviewAverage
      
      t.integer   :printer_id

      t.timestamps
    end
  end

  def self.down
    drop_table :best_buy_printers
  end
end
