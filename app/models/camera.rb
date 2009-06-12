require 'product'
class Camera < ActiveRecord::Base
  include ProductProperties
  has_many :camera_nodes
  is_indexed :fields => ['title', 'feature']
  named_scope :valid, :conditions => "brand IS NOT NULL AND maximumresolution IS NOT NULL AND opticalzoom IS NOT NULL AND listpriceint IS NOT NULL AND displaysize IS NOT NULL"
  named_scope :invalid, :conditions => "brand IS NULL OR maximumresolution IS NULL OR opticalzoom IS NULL OR listpriceint IS NULL OR displaysize IS NULL"
  named_scope :instock, :conditions => "instock is true"
  InterestingFeatures = %w(pricestr brand digitalzoom displaysize itemheight itemlength itemwidth itemweight label listpricestr maximumresolution maximumfocallength minimumfocallength model opticalzoom packageheight packageweight packagelength packagewidth title merchant iseligibleforsupersavershipping)
  ContinuousFeatures = %w(maximumresolution displaysize opticalzoom)
  CategoricalFeatures = %w(brand)
  BinaryFeatures = []
  ContinuousFeaturesDisp = %w(Megapixels Display\ Size Optical\ Zoom)
  ContinuousFeaturesLabel = Hash[*ContinuousFeatures.zip(['','in','X']).flatten]
  ShowFeatures = %w(brand model maximumresolution opticalzoom digitalzoom displaysize maximumfocallength minimumfocallength batterydescription hasredeyereduction itemweight itemwidth packagewidth)
  ShowFeaturesDisp = %w(Brand Model Megapixels Optical\ Zoom Digital\ Zoom Display\ Size Maximum\ Focal\ Length Minimum\ Focal\ Length Battery Red\ Eye\ Reduction Weight Camera\ Width Package\ Width)

  def myvalid?
    instock && !(maximumresolution.nil? || displaysize.nil? || opticalzoom.nil? || salepriceint.nil?)
  end
end
