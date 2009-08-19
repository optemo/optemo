require 'product'
class Camera < ActiveRecord::Base
  include ProductProperties
  has_many :camera_nodes
  is_indexed :fields => ['title', 'feature']
           #                                      (c)luster 
           #                                      (f)ilter 
           #   db_name                Type        (e)xtra Display                              Label       Low Desc                Average Desc                   High Desc         #Very Low Desc           Very High Desc
  Features = [%w(price                Continuous  cf                  Price                    \           Cheap                   Average\ Price                 Average\ Price),    #Very\ Cheap            Expensive),
              %w(maximumresolution    Continuous  cf                  Resolution               MP          Average\ Resolution     Somewhat\ High\ Resolution     High\ Resolution),  #Low\ Resolution        Very\ High\ Resolution),
              %w(opticalzoom          Continuous  cf                  Optical\ Zoom            X           Average\ Zoom           Somewhat\ Zoom                 High\ Zoom),        #Low\ Zoom              Very\ High\ Zoom),
              %w(displaysize          Continuous  cf                  Display\ Size            in          Somewhat\ Small\ LCD    Average\ LCD                   Large\ LCD),        #Small\ LCD             Very\ Large\ LCD),
              %w(brand                Categorical f                   Brand                    \           \                        \                             \ )]                # \                      \)]
                                                                                                                                                                                   
  ContinuousFeatures = Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[0]}
  
  $PrefDirection = Hash.new(1) 
  ContinuousFeatures.each {|f| $PrefDirection[f]=1}
  $PrefDirection["price"] = -1
  $PrefDirection["itemweight"] = -1
  ContinuousFeaturesF = Features.select{|f|f[1] == "Continuous" && f[2].index("f")}.map{|f|f[0]}
  BinaryFeatures = Features.select{|f|f[1] == "Binary" && f[2].index("c")}.map{|f|f[0]}
  BinaryFeaturesF = Features.select{|f|f[1] == "Binary" && f[2].index("f")}.map{|f|f[0]}
  CategoricalFeatures = Features.select{|f|f[1] == "Categorical" && f[2].index("c")}.map{|f|f[0]}
  CategoricalFeaturesF = Features.select{|f|f[1] == "Categorical" && f[2].index("f")}.map{|f|f[0]}
  FeaturesLabel = Hash[*Features.select{|f|f[4] != " "}.map{|f|f[0]}.zip(Features.select{|f|f[4] != " "}.map{|f|f[4]}).flatten]
  FeaturesDisp = Hash[*Features.map{|f|f[0]}.zip(Features.map{|f|f[3]}).flatten]
  #ContinuousFeaturesDescLlow = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[5]}).flatten]
  ContinuousFeaturesDescLow = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[6]}).flatten]
  ContinuousFeaturesDescHigh = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[8]}).flatten]
  #ContinuousFeaturesDescHhigh = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[9]}).flatten]
  ContinuousFeaturesDescAverage = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[7]}).flatten]
  BinaryFeaturesDesc = Hash[*BinaryFeatures.zip(Features.select{|f|f[1] == "Binary" && f[2].index("c")}.map{|f|f[3]}).flatten]
  ExtraFeature = Hash[*Features.select{|f|f[2].index("e")}.map{|f|[f[0],true]}.flatten]
  ShowFeatures = %w(brand model maximumresolution opticalzoom digitalzoom displaysize itemweight itemwidth)
  ShowFeaturesDisp = %w(Brand Model Resolution Optical\ Zoom Digital\ Zoom Display\ Size Weight Camera\ Width)
  DisplayedFeatures = %w(pricestr brand digitalzoom displaysize itemdimensions itemweight label maximumresolution model opticalzoom title)
  FInfo = {
    "brand" => "Brands: The manufacturer of the product. You can choose more than just one brand.",
    "maximumresolution" => "Maximum Resolution: The number of pixels in the image that is stored.",
    "displaysize" => "Display Size: The diagonal length of the LCD display.",
    "opticalzoom" => "Optical Zoom: The zoom multiple of the camera lens.",
    "price" => "Price: The lowest price for the item.",
    "itemweight" => "Weight: The weight of the camera in grams. If it is an SLR only the camera body, not the lens is counted.",
    "slr" => "SLR: Single-lens reflex cameras use a semi-automatic mirroring system to allow you to see exactly what is captured. They all have interchangeable lenses.",
    "bulb" => "Bulb Mode: Lets you control the shutter with the button.",
    "waterproof" => "Water Proof: "
    }
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),['brand','model'].map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"
#  named_scope :valid_and_modelled, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  def self.urlname
    @urlname ||= name.pluralize.downcase
  end
  # Show Features to Continuous Features dictionary
  def self.SFtoCFdictionary(sf)
    sf
  end
end