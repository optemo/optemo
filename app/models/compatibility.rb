class Compatibility < ActiveRecord::Base
    ReqdFeatures = %w(accessory_id accessory_type product_id product_type)
    scope :valid, :conditions => ReqdFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')
  
end
