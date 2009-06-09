require 'product'
class Printer < ActiveRecord::Base
  include ProductProperties
  #Ultrasphinx field selection
  is_indexed :fields => ['title', 'feature']
  named_scope :priced, :conditions => "salepriceint IS NOT NULL"
  named_scope :valid, :conditions => %w(ppm itemwidth paperinput salepriceint resolutionarea scanner printserver).map{|i|i+' IS NOT NULL'}.join(' AND ')
  named_scope :invalid, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')+" OR (salepriceint IS NULL AND listpriceint IS NULL)"
  named_scope :fewfeatures, :conditions => %w(ppm ttp paperinput).map{|i|i+' IS NULL'}.join(' OR ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :newfeatures, :conditions => %w(ppm itemwidth paperinput resolutionarea salepriceint scanner printserver).map{|i|i+' IS NOT NULL'}.join(' AND ')
  MainFeatures = %w(ppm itemwidth paperinput resolutionarea)
  BinaryFeatures = %w(scanner printserver)
  MainFeaturesDisp = %w(Pages\ Per\ Minute Width Paper\ Tray\ Size)
  MainFeaturesLabel = Hash[*MainFeatures.zip(['','in','']).flatten]
  ShowFeatures = %w(brand model ppm paperinput ttp resolution itemwidth itemheight itemlength duplex connectivity papersize scanner printserver platform)
  ShowFeaturesDisp = %w(Brand Model Pages\ Per\ Minute Paper\ Tray\ Size Time\ To\ Print Resolution Width Height Length Duplex Connectivity Paper\ Size Scanner Print\ Server OS)
  InterestingFeatures = %w(brand ppm ttp resolution duplex connectivity papersize paperoutput dimensions dutycycle paperinput ppmcolor platform colorprinter scanner printserver itemheight itemlength itemwidth itemweight manufacturer model packageheight packagelength packagewidth packageweight)
  
  def myvalid?
    instock && !(ppm.nil? || itemwidth.nil? || paperinput.nil? || salepriceint.nil? || resolutionarea.nil? || scanner.nil? || printserver.nil?)
  end
end

