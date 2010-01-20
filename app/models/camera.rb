class Camera < ActiveRecord::Base
  include ProductProperties
  has_many :camera_nodes
  define_index do
    #fields
    indexes title
    #attributes
  end
           #                                (c)luster 
           #                                (f)ilter 
           #                                (d)escription for groups
           #                                (t)ext for single product description
           #                                (x)compared
           #     db_name           Type     (e)xtra Display
  Features = [%w(price                Continuous  cf    ),
              %w(maximumresolution    Continuous  tcf    ),
              %w(opticalzoom          Continuous  tcf    ),
              %w(displaysize          Continuous  tcf    ),
              %w(brand                Categorical f     )]
                                                                                                                                                                                   
  ContinuousFeatures = Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[0]}
  DescFeatures = Features.select{|f|f[2].index("d")}.map{|f|f[0]}
  SingleDescFeatures = Features.select{|f|f[2].index("t")}.map{|f|f[0]}
  ContinuousFeaturesF = Features.select{|f|f[1] == "Continuous" && f[2].index("f")}.map{|f|f[0]}
  BinaryFeatures = Features.select{|f|f[1] == "Binary" && f[2].index("c")}.map{|f|f[0]}
  BinaryFeaturesF = Features.select{|f|f[1] == "Binary" && f[2].index("f")}.map{|f|f[0]}
  CategoricalFeatures = Features.select{|f|f[1] == "Categorical"}.map{|f|f[0]}
  CategoricalFeaturesF = Features.select{|f|f[1] == "Categorical" && f[2].index("f")}.map{|f|f[0]}
  ExtraFeature = Hash[*Features.select{|f|f[2].index("e")}.map{|f|[f[0],true]}.flatten]
  ShowFeatures = %w(brand model maximumresolution opticalzoom digitalzoom displaysize ) #itemweight itemwidth sensordiagonal crushproof freezeproof waterproof aa_batteries aperturerange minimumfocallength maximumfocallength minf shutterspeedrange slr)
  DisplayedFeatures = %w(displaysize opticalzoom maximumresolution itemweight itemdimensions digitalzoom)
  ItoF = %w(price itemwidth)
  ValidRanges = { 'itemheight' => [200,450], 'itemlength' => [55,350], 'itemwidth' => [350,600], \
    'maximumresolution' => [0.2, 50], 'opticalzoom' => [1,26], 'digitalzoom' => [1, 100], \
    'displaysize' => [0.5,4], 'itemweight' => [0_20,8_00]} #, 'priceint' => [1_00, 10_000_00] }
  MinPrice = 1_00
  MaxPrice = 10_000_00
  
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),['brand','model'].map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"
  named_scope :valid_and_modelled, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),['brand','model', 'aa_batteries', 'maximumshutterspeed'].map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  def self.urlname
    @urlname ||= name.pluralize.downcase
  end
end