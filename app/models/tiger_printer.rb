class TigerPrinter < ActiveRecord::Base
  ContinuousFeatures = %w(ppm itemwidth paperinput resolutionmax)
  BinaryFeatures = %w(scanner printserver)
  scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  scope :instock, :conditions => "instock is true"
  scope :instock_ca, :conditions => "instock_ca is true"

end
