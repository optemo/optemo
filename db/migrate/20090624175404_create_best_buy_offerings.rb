class CreateBestBuyOfferings < ActiveRecord::Migration
  def self.up
    create_table :best_buy_offerings do |t|
      t.integer   :retailer_offering_id
      
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
      t.timestamps
    end
  end

  def self.down
    drop_table :best_buy_offerings
  end
end
