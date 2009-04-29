class RetailerOffering < ActiveRecord::Base
  belongs_to :retailer
  has_many :referrals
end
