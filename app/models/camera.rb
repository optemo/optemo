require 'product'
class Camera < ActiveRecord::Base
  include ProductProperties
  has_many :camera_nodes
  is_indexed :fields => ['title', 'feature']
  InterestingFeatures = %w(pricestr brand digitalzoom displaysize itemheight itemlength itemwidth itemweight label listpricestr maximumresolution maximumfocallength minimumfocallength model opticalzoom packageheight packageweight packagelength packagewidth title merchant iseligibleforsupersavershipping)
  ContinuousFeatures = %w(maximumresolution displaysize opticalzoom price)
  CategoricalFeatures = %w(brand)
  BinaryFeatures = []
  ContinuousFeaturesDisp = %w(Megapixels Display\ Size Optical\ Zoom Price)
  ContinuousFeaturesLabel = Hash[*ContinuousFeatures.zip(['','in','X','']).flatten]
  ContinuousFeaturesDescLow = Hash[*ContinuousFeatures.zip(['Low Resolution', 'Small Screen', 'Low Zoom', 'Cheap']).flatten]
  ContinuousFeaturesDescHigh = Hash[*ContinuousFeatures.zip(['High Resolution', 'Large Screen', 'High Zoom', 'Expensive']).flatten]
  ShowFeatures = %w(brand model maximumresolution opticalzoom digitalzoom displaysize maximumfocallength minimumfocallength batterydescription hasredeyereduction itemweight itemwidth packagewidth)
  ShowFeaturesDisp = %w(Brand Model Megapixels Optical\ Zoom Digital\ Zoom Display\ Size Maximum\ Focal\ Length Minimum\ Focal\ Length Battery Red\ Eye\ Reduction Weight Camera\ Width Package\ Width)
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
