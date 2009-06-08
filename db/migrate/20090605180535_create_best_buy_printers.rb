class CreateBestBuyPrinters < ActiveRecord::Migration
  def self.up
    create_table :best_buy_printers do |t|
      t.integer   :classId
      t.string    :affiliateAddToCartUrl
      t.boolean   :active
      t.datetime  :priceUpdateDate
      t.string    :accessoriesImage
      t.boolean   :printOnly
      t.string    :upc
      t.string    :sku
      t.string    :color
      t.integer   :productId
      t.string    :alternateViewsImage
      t.datetime  :inStoreAvailabilityUpdateDate
      t.string    :warrantyParts
      t.string    :modelNumber
      t.integer   :customerReviewCount
      t.float     :customerReviewAverage
      t.string    :shortDescription
      t.string    :addToCartUrl
      t.string    :dollarSavings
      t.datetime  :onlineAvailabilityUpdateDate
      t.float     :salePrice
      t.string    :leftViewImage
      t.string    :manufacturer
      t.string    :weight
      t.string    :inStoreAvailabilityText
      t.string    :largeImage
      t.string    :image
      t.string    :warrantyLabor
      t.integer   :departmentId
      t.string    :description
      t.string    :categoryPath
      t.float     :width
      t.string    :specialOrder
      t.string    :format
      t.string    :affiliateUrl
      t.string    :topViewImage
      t.string    :onlineAvailabilityText
      t.float     :regularPrice
      t.string    :energyGuideImage
      t.boolean   :inStoreAvailability
      t.string    :source
      t.string    :bb_class
      t.string    :thumbnailImage
      t.float     :shippingWeight
      t.string    :cjAffiliateAddToCartUrl
      t.string    :department
      t.string    :mobileUrl
      t.string    :rightViewImage
      t.string    :name
      t.float     :height
      t.float     :shippingCost
      t.string    :backViewImage
      t.string    :url
      t.string    :onlineAvailability
      t.string    :activeUpdateDate
      t.boolean   :bb_new
      t.boolean   :freeShipping
      t.string    :subclass
      t.string    :type
      t.string    :mediumImage
      t.string    :orderable
      t.string    :cjAffiliateUrl
      t.integer   :subclassId
      t.boolean   :nationalFeatured
      t.string    :remoteControlImage
      t.string    :largeFrontImage
      t.boolean   :navigability
      t.datetime  :releaseDate
      t.datetime  :startDate
      t.string    :angleImage
      t.float     :depth
      t.datetime  :itemUpdateDate
      t.text      :longDescription
      
      t.integer   :printer_id

      t.timestamps
    end
  end

  def self.down
    drop_table :best_buy_printers
  end
end
