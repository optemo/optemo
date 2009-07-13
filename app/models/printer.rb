require 'product'
class Printer < ActiveRecord::Base
  include ProductProperties
  #Ultrasphinx field selection
  is_indexed :fields => ['title', 'feature']
  ContinuousFeatures = %w(ppm itemwidth paperinput resolutionmax price)
  BinaryFeatures = %w(scanner printserver)
  CategoricalFeatures = %w(brand)
  ContinuousFeaturesDisp = %w(Pages\ Per\ Minute Width Paper\ Tray\ Size Resolution Price)
  ContinuousFeaturesLabel = Hash[*ContinuousFeatures.zip(['','in','','dpi','']).flatten]
  ContinuousFeaturesDescLow = Hash[*ContinuousFeatures.zip(['Slow', 'Small', 'Low Capacity', 'Low Resolution', 'Cheap']).flatten]
  ContinuousFeaturesDescHigh = Hash[*ContinuousFeatures.zip(['Fast', 'Large', 'High Capacity', 'High Resolution', 'Expensive']).flatten]
  ShowFeatures = %w(brand model ppm paperinput ttp resolution itemwidth itemheight itemlength duplex connectivity papersize scanner printserver platform)
  ShowFeaturesDisp = %w(Brand Model Pages\ Per\ Minute Paper\ Tray\ Size Time\ To\ Print Resolution Width Height Length Duplex Connectivity Paper\ Size Scanner Print\ Server OS)
  InterestingFeatures = %w(brand price ppm ttp resolution colorprinter scanner printserver duplex connectivity papersize paperoutput dimensions dutycycle paperinput ppmcolor platform itemheight itemlength itemwidth itemweight packageheight packagelength packagewidth packageweight)
  DisplayedFeatures = %w(brand price ppm ttp resolution colorprinter scanner printserver duplex connectivity papersize paperoutput dutycycle paperinput ppmcolor platform itemdimensions itemweight packagedimensions packageweight)
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :fewfeatures, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')
  named_scope :instock, :conditions => "instock is true"
  
  def self.urlname
    @urlname ||= name.pluralize.downcase
  end  
end

