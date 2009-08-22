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
  DisplayedFeatures = %w(ppm ttp resolution colorprinter scanner printserver duplex connectivity papersize paperoutput dutycycle paperinput ppmcolor platform itemdimensions itemweight packagedimensions packageweight)
  FInfo = {
    "brand" => "Brands: The manufacturer of the product. You can choose more than just one brand.",
    "ppm" => "Pages Per Minute: The number of pages that can be printed per minute in black and white.",
    "itemwidth" => "Display Size: The diagonal length of the LCD display.",
    "paperinput" => "Paper Tray Size: The number of blank sheets of paper the printer can hold.",
    "resolutionmax" => "Resolution: The largest resolution (in dots per inch) of either the vertical or horizontal direction.",
    "price" => "Price: The lowest price for the item.",
    "scanner" => "Scanner: Click here to select printers that can scan documents.",
    "printserver" => "Printer Server: Click here to select printers that have wired or wireless networking. A printserver can be used by multiple computers without having to be connected to a computer that is always on."
    }
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :fewfeatures, :conditions => %w(ppm itemwidth paperinput).map{|i|i+' IS NULL'}.join(' OR ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"
  def self.urlname
    @urlname ||= name.pluralize.downcase
  end  
  
  # Show Features to Continuous Features dictionary
  def self.SFtoCFdictionary(sf)
    case sf
      when "resolution": 
      	return "resolutionmax"
      else 
        return sf
      end
  end
end

