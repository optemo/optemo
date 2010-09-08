class ScrapedCamera < ActiveRecord::Base
  
  #LinkingFeatures = ['retailer_id','product_id','local_id']
  
  #scope :priced, :conditions => "price > 0"
  #scope :well_linked, :conditions => [LinkingFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),].delete_if{|l|l.blank?}.join(' AND ')
  #scope :priced, :conditions => "price > 0"
  #scope :priced, :conditions => "price > 0"
  #scope :priced, :conditions => "price > 0"
end
