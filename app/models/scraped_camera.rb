class ScrapedCamera < ActiveRecord::Base
  
  LinkingFeatures = ['retailer_id','product_id','local_id']
  
  #named_scope :priced, :conditions => "price > 0"
  named_scope :well_linked, :conditions => [LinkingFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),].delete_if{|l|l.blank?}.join(' AND ')
  #named_scope :priced, :conditions => "price > 0"
  #named_scope :priced, :conditions => "price > 0"
  #named_scope :priced, :conditions => "price > 0"
end
