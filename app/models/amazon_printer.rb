class AmazonPrinter < ActiveRecord::Base
  named_scope :priced, :conditions => "price IS NOT NULL"
  named_scope :valid, :conditions => %w(ppm itemwidth paperinput price resolutionmax scanner printserver).map{|i|i+' IS NOT NULL'}.join(' AND ')
  named_scope :invalid, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')+" OR (price IS NULL AND listpriceint IS NULL)"
  named_scope :fewfeatures, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :newfeatures, :conditions => %w(ppm itemwidth paperinput resolutionmax price scanner printserver).map{|i|i+' IS NOT NULL'}.join(' AND ')
end
