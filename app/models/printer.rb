require 'product'
class Printer < ActiveRecord::Base
  include ProductProperties
  #Ultrasphinx field selection
  is_indexed :fields => ['title', 'feature']
           #                                (c)luster 
           #                                (f)ilter 
           #     db_name           Type     (e)xtra Display          Label              Low Desc        High Desc                         # Very Low Desc      Very High Desc
  Features = [%w(ppm               Continuous  cf  Printing\ Speed     ppm                Slow            Fast   ),                         # Very\ Slow         Very\ Fast),
              %w(itemwidth         Continuous  cf  Width               in.              Small           Large  ),                         # Very\ Small        Very\ Large),
              %w(paperinput        Continuous  cf  Paper\ Tray\ Size   pages                Low\ Capacity   High\ Capacity),                  # Low\ Capacity      Very\ High\ Capacity),
              %w(resolutionmax     Continuous  cf  Resolution          dpi             Low\ Resolution High\ Resolution),                # Low\ Resolution    Very\ High\ Resolution),
              %w(price             Continuous  cf  Price               $                Cheap           Expensive),                       # Very\ Cheap        Expensive),
              %w(brand             Categorical f   Brand               \                \               \                  ),             # \                  \ ),
              %w(scanner           Binary      cf  Scanner             \                \               \                  ),             # \                  \ ),
              %w(printserver       Binary      cf  Networked\ Printer  \                \               \                  )]             # \                  \ )]
  
  ContinuousFeatures = Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[0]}
  ContinuousFeaturesF = Features.select{|f|f[1] == "Continuous" && f[2].index("f")}.map{|f|f[0]}
  BinaryFeatures = Features.select{|f|f[1] == "Binary" && f[2].index("c")}.map{|f|f[0]}
  BinaryFeaturesF = Features.select{|f|f[1] == "Binary" && f[2].index("f")}.map{|f|f[0]}
  CategoricalFeatures = Features.select{|f|f[1] == "Categorical" && f[2].index("c")}.map{|f|f[0]}
  CategoricalFeaturesF = Features.select{|f|f[1] == "Categorical" && f[2].index("f")}.map{|f|f[0]}
  FeaturesLabel = Hash[*Features.select{|f|f[4] != " "}.map{|f|f[0]}.zip(Features.select{|f|f[4] != " "}.map{|f|f[4]}).flatten]
  FeaturesDisp = Hash[*Features.map{|f|f[0]}.zip(Features.map{|f|f[3]}).flatten]
  ContinuousFeaturesDescLlow = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[5]}).flatten]
  ContinuousFeaturesDescLow = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[5]}).flatten]
  ContinuousFeaturesDescHigh = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[6]}).flatten]
  ContinuousFeaturesDescHhigh = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[6]}).flatten]
  ExtraFeature = Hash[*Features.select{|f|f[2].index("e")}.map{|f|[f[0],true]}.flatten]
  ShowFeatures = %w(brand model ppm paperinput ttp resolution itemwidth itemheight itemlength duplex connectivity papersize scanner printserver platform)
  ShowFeaturesDisp = %w(Brand Model Pages\ Per\ Minute Paper\ Tray\ Size Time\ To\ Print Resolution Width Height Length Duplex Connectivity Paper\ Size Scanner Print\ Server OS)
  DisplayedFeatures = %w(ppm ttp resolution colorprinter scanner printserver duplex connectivity papersize paperoutput dutycycle paperinput ppmcolor platform itemdimensions itemweight packagedimensions packageweight)
  FInfo = {
    "brand" => "Brands: The manufacturer of the product. You can choose more than just one brand.",
    "ppm" => "Pages Per Minute: The number of pages that can be printed per minute in black and white.",
    "itemwidth" => "Width: The width of the printer accross the front.",
    "paperinput" => "Paper Tray Size: The number of blank sheets of paper the printer can hold.",
    "resolutionmax" => "Resolution: The largest resolution (in dots per inch) of either the vertical or horizontal direction.",
    "price" => "Price: The lowest price for the item.",
    "scanner" => "Scanner: Printers that can scan documents.",
    "printserver" => "Printer Server: Printers that have wired or wireless networking. A printserver can be used by multiple computers without having to be connected to a computer that is always on."
    }
    
    
  ItoF = %w(price itemwidth)

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

