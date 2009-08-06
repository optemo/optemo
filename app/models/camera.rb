require 'product'
class Camera < ActiveRecord::Base
  include ProductProperties
  has_many :camera_nodes
  is_indexed :fields => ['title', 'feature']
           #                                (c)luster 
           #                                (f)ilter 
           #     db_name           Type     (e)xtra Display     Label   Low Desc     High Desc  
  Features = [%w(maximumresolution Continuous  cf  Resolution     MP  Low\ Resolution High\ Resolution),
              %w(displaysize       Continuous  cf  Display\ Size  in. Small\ Screen   Large\ Screen),
              %w(opticalzoom       Continuous  cf  Optical\ Zoom  X   Low\ Zoom       High\ Zoom),
              %w(price             Continuous  cf  Price          \   Cheap           Expensive),
              %w(brand             Categorical f   Brand          \   \               \ )]
  
  ContinuousFeatures = Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[0]}
  ContinuousFeaturesF = Features.select{|f|f[1] == "Continuous" && f[2].index("f")}.map{|f|f[0]}
  BinaryFeatures = Features.select{|f|f[1] == "Binary" && f[2].index("c")}.map{|f|f[0]}
  BinaryFeaturesF = Features.select{|f|f[1] == "Binary" && f[2].index("f")}.map{|f|f[0]}
  CategoricalFeatures = Features.select{|f|f[1] == "Categorical" && f[2].index("c")}.map{|f|f[0]}
  CategoricalFeaturesF = Features.select{|f|f[1] == "Categorical" && f[2].index("f")}.map{|f|f[0]}
  FeaturesLabel = Hash[*Features.select{|f|f[4] != " "}.map{|f|f[0]}.zip(Features.select{|f|f[4] != " "}.map{|f|f[4]}).flatten]
  FeaturesDisp = Hash[*Features.map{|f|f[0]}.zip(Features.map{|f|f[3]}).flatten]
  ContinuousFeaturesDescLow = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[5]}).flatten]
  ContinuousFeaturesDescHigh = Hash[*ContinuousFeatures.zip(Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[6]}).flatten]
  ExtraFeature = Hash[*Features.select{|f|f[2].index("e")}.map{|f|[f[0],true]}.flatten]
  ShowFeatures = %w(brand model maximumresolution opticalzoom digitalzoom displaysize batterydescription hasredeyereduction itemweight itemwidth)
  ShowFeaturesDisp = %w(Brand Model Megapixels Optical\ Zoom Digital\ Zoom Display\ Size Battery Red\ Eye\ Reduction Weight Camera\ Width)
  DisplayedFeatures = %w(pricestr brand digitalzoom displaysize itemdimensions itemweight label maximumresolution model opticalzoom title)
  FInfo = {
    "brand" => "Brands: The manufacturer of the product. You can choose more than just one brand.",
    "maximumresolution" => "Maximum Resolution: The number of pixels in the image that is stored.",
    "displaysize" => "Display Size: The diagonal length of the LCD display.",
    "opticalzoom" => "Optical Zoom: The zoom multiple of the camera lens.",
    "price" => "Price: The lowest price for the item."
    }
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"
  
  def self.urlname
    @urlname ||= name.pluralize.downcase
  end
end
