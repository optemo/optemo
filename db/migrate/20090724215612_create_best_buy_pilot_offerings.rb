class CreateBestBuyPilotOfferings < ActiveRecord::Migration
  def self.up
    create_table :best_buy_pilot_offerings do |t|

       t.timestamps

       t.primary_key :id

       # Offering-specific
       t.string      :category
       t.string      :categoryid
       t.string      :catgroup
       t.string      :catsubclass
       t.string      :fsskuid
       t.string      :skuid
       t.string      :guid
       t.string      :webcode
       
       # Link to BestBuyCamera
       t.integer     :bb_camera_id
       
       # Links 'n stuff
       t.text       :link
       t.text       :imageurl
       t.text       :glossary

       # Prices 'n stuff
       t.string     :saleenddate
       t.string     :saleprice
       t.string     :savings

       t.string     :pricestr
       t.integer    :priceint
       
       # Standard offering stuff
       t.integer    :product_id
       t.string     :product_type
       t.integer    :retailer_id
       t.string     :pricehistory
       t.string     :region

       t.datetime   :priceUpdate
       t.integer    :shippingCost
       t.integer    :tax
       t.string     :state
       t.boolean    :stock
       t.boolean    :toolow
       t.string     :availability
       t.datetime   :availabilityUpdate
       t.text       :url
       t.boolean    :active
       t.datetime   :activeUpdate
       t.boolean    :freeShipping
       
      end
  end

  def self.down
    drop_table :best_buy_pilot_offerings
  end
end
