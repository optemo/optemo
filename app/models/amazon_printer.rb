class AmazonPrinter < ActiveRecord::Base
  scope :priced, :conditions => "price IS NOT NULL"
  scope :valid, :conditions => %w(ppm itemwidth paperinput price resolutionmax scanner printserver).map{|i|i+' IS NOT NULL'}.join(' AND ')
  scope :invalid, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')+" OR (price IS NULL AND listpriceint IS NULL)"
  scope :fewfeatures, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')
  scope :instock, :conditions => "instock is true"
  scope :newfeatures, :conditions => %w(ppm itemwidth paperinput resolutionmax price scanner printserver).map{|i|i+' IS NOT NULL'}.join(' AND ')
end
