class TigerOffering < ActiveRecord::Base
  ContinuousFeatures = %w(priceint)
  BinaryFeatures = %w(stock)
  #named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "stock is true"
  named_scope :priced, :conditions => 'priceint is not null'
end
