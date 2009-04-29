class Referral < ActiveRecord::Base
  belongs_to :session
  belongs_to :retailer_offering
end
