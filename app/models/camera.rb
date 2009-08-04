require 'product'
class Camera < ActiveRecord::Base
  include ProductProperties
  has_many :camera_nodes
  is_indexed :fields => ['title', 'feature']
  ContinuousFeatures      = %w(maximumresolution itemweight opticalzoom   price)
  ContinuousFeaturesDisp  = %w(Resolution        Weight     Optical\ Zoom Price)
  Label                   = %w(MP                g          X                  )
  Low                     = %w(Low\ Resolution   Light      Low\ Zoom     Cheap)  
  High                    = %w(High\ Resolution  Heavy      High\ Zoom    Expensive)
  ContinuousFeaturesF = ContinuousFeatures +          %w()
  ContinuousFeaturesFDisp = ContinuousFeaturesDisp +  %w()
  LabelF = Label +                                    %w()
  CategoricalFeatures = %w(brand)
  CDisp               = %w(Brand)
  BinaryFeatures = %w(slr)
  BFDisp         = %w(SLR)
  BinaryFeaturesF = BinaryFeatures + %w(bulb)
  BFFDisp = BFDisp +                 %w(Bulb)
  
  ContinuousFeaturesFLabel = Hash[*ContinuousFeaturesF.zip(LabelF).flatten]
  ContinuousFeaturesDescLow = Hash[*ContinuousFeatures.zip(Low).flatten]
  ContinuousFeaturesDescHigh = Hash[*ContinuousFeatures.zip(High).flatten]
  BinaryFeaturesDisp = Hash[*BinaryFeatures.zip(BFDisp).flatten]
  BinaryFeaturesFDisp= Hash[*BinaryFeaturesF.zip(BFFDisp).flatten]
  CategoricalFeaturesDisp = Hash[*CategoricalFeatures.zip(CDisp).flatten]
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
