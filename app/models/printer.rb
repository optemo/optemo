require 'product'
class Printer < ActiveRecord::Base
  include ProductProperties
  #Ultrasphinx field selection
  is_indexed :fields => ['title', 'feature']
  named_scope :priced, :conditions => "price IS NOT NULL"
  named_scope :valid, :conditions => %w(ppm itemwidth paperinput price resolutionmax scanner printserver).map{|i|i+' IS NOT NULL'}.join(' AND ')
  named_scope :invalid, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')+" OR (price IS NULL AND listpriceint IS NULL)"
  named_scope :fewfeatures, :conditions => %w(ppm ttp paperinput).map{|i|i+' IS NULL'}.join(' OR ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :newfeatures, :conditions => %w(ppm itemwidth paperinput resolutionmax price scanner printserver).map{|i|i+' IS NOT NULL'}.join(' AND ')
  ContinuousFeatures = %w(ppm itemwidth paperinput resolutionarea price)
  BinaryFeatures = %w(scanner printserver)
  CategoricalFeatures = %w(brand)
  ContinuousFeaturesDisp = %w(Pages\ Per\ Minute Width Paper\ Tray\ Size Resolution Price)
  ContinuousFeaturesLabel = Hash[*ContinuousFeatures.zip(['','in','','dpi','']).flatten]
  ContinuousFeaturesDescLow = Hash[*ContinuousFeatures.zip(['Slow', 'Small', 'Low Capacity', 'Low Resolution', 'Cheap']).flatten]
  ContinuousFeaturesDescHigh = Hash[*ContinuousFeatures.zip(['Fast', 'Large', 'High Capacity', 'High Resolution', 'Expensive']).flatten]
  ShowFeatures = %w(brand model ppm paperinput ttp resolution itemwidth itemheight itemlength duplex connectivity papersize scanner printserver platform)
  ShowFeaturesDisp = %w(Brand Model Pages\ Per\ Minute Paper\ Tray\ Size Time\ To\ Print Resolution Width Height Length Duplex Connectivity Paper\ Size Scanner Print\ Server OS)
  # Older interesting features
  # InterestingFeatures = %w(brand ppm ttp resolution duplex connectivity papersize paperoutput dimensions dutycycle paperinput ppmcolor platform colorprinter scanner printserver itemheight itemlength itemwidth itemweight manufacturer model packageheight packagelength packagewidth packageweight)
  InterestingFeatures = %w(brand ppm ttp resolution colorprinter scanner printserver duplex connectivity papersize paperoutput dimensions dutycycle paperinput ppmcolor platform itemheight itemlength itemwidth itemweight packageheight packagelength packagewidth packageweight)
  DisplayedFeatures = %w(brand ppm ttp resolution colorprinter scanner printserver duplex connectivity papersize paperoutput dutycycle paperinput ppmcolor platform itemdimensions itemweight packagedimensions packageweight)
  
  # Currently only 4 preferences
  PreferenceFeatures = %w(ppm itemwidth paperinput price)
  
  def myvalid?
    instock && !(ppm.nil? || itemwidth.nil? || paperinput.nil? || price.nil? || resolutionmax.nil? || scanner.nil? || printserver.nil?)
  end
  
end

