class TigerPrinter < ActiveRecord::Base
  
  include ProductProperties
  ContinuousFeatures = %w(ppm itemwidth paperinput resolutionmax)
  BinaryFeatures = %w(scanner printserver)
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"

end
