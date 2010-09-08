class AmazonAll < ActiveRecord::Base
  ContinuousFeatures = %w(ppm itemwidth paperinput resolutionmax price)
  BinaryFeatures = %w(scanner printserver)
  CategoricalFeatures = %w(brand)
  
  scope :priced, :conditions => "price > 0"
  scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  scope :fewfeatures, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')
  scope :instock, :conditions => "instock is true"
end
