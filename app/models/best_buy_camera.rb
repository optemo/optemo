class BestBuyCamera < ActiveRecord::Base
  # Copied from Camera.

  ContinuousFeatures = %w(maximumresolution displaysize opticalzoom listpriceint)
  CategoricalFeatures = %w(brand)
  BinaryFeatures = []
  #ContinuousFeaturesDisp = %w(Megapixels Display\ Size Optical\ Zoom Price)
  #ContinuousFeaturesLabel = Hash[*ContinuousFeatures.zip(['','in','X','']).flatten]
  #ContinuousFeaturesDescLow = Hash[*ContinuousFeatures.zip(['Low Resolution', 'Small Screen', 'Low Zoom', 'Cheap']).flatten]
  #ContinuousFeaturesDescHigh = Hash[*ContinuousFeatures.zip(['High Resolution', 'Large Screen', 'High Zoom', 'Expensive']).flatten]
  #ShowFeatures = %w(brand model maximumresolution opticalzoom digitalzoom displaysize maximumfocallength minimumfocallength batterydescription hasredeyereduction itemweight itemwidth packagewidth)
  #ShowFeaturesDisp = %w(Brand Model Megapixels Optical\ Zoom Digital\ Zoom Display\ Size Maximum\ Focal\ Length Minimum\ Focal\ Length Battery Red\ Eye\ Reduction Weight Camera\ Width Package\ Width)

  named_scope :priced, :conditions => "listpriceint > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  
  
end
