class Review < ActiveRecord::Base
  named_scope :linked, :conditions => "product_id IS NOT NULL"
end
