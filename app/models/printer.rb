require 'product'
class Printer < ActiveRecord::Base
  include ProductProperties
  named_scope :priced, :conditions => "salepriceint IS NOT NULL"
  named_scope :valid, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NOT NULL'}.join(' AND ')+" AND (salepriceint IS NOT NULL OR listpriceint IS NOT NULL)"
  named_scope :invalid, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')+" OR (salepriceint IS NULL AND listpriceint IS NULL)"
  named_scope :fewfeatures, :conditions => %w(ppm ttp paperinput).map{|i|i+' IS NULL'}.join(' OR ')
  MainFeatures = %w(ppm itemwidth paperinput)
  MainFeaturesDisp = %w(Pages\ Per\ Minute Width Paper\ Tray\ Size)
  MainFeaturesLabel = Hash[*MainFeatures.zip(['','in','']).flatten]
end
