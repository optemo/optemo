class Review < ActiveRecord::Base
  scope :linked, :conditions => "product_id IS NOT NULL"
end
