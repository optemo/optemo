class CreateBestBuyProducts < ActiveRecord::Migration
  def self.up
    create_table :best_buy_products do |t|
      t.integer   :product_id
      t.string    :product_type
      
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
      
      t.integer   :customerReviewCount
      t.float     :customerReviewAverage
      t.timestamps
    end
  end

  def self.down
    drop_table :best_buy_products
  end
end
