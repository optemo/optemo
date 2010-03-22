class Printer < ActiveRecord::Base
  include ProductProperties
  def self.productcache(id) 
    # Caching is better using class variable; do not change to memcached.
    # Hash key must be based on model name (camera/printer), region, and feature name together to guarantee uniqueness.
    unless defined? @@printers
      @@printers = {}
    end
    unless @@printers.has_key?('Printer' + $region + id.to_s)
      @@printers[('Printer' + $region + id.to_s)] = Session.current.findCachedProduct(id)
    end
    @@printers[('Printer' + $region + id.to_s)]
  end
  #Ultrasphinx field selection
  define_index do
    #fields
    indexes "LOWER(title)", :as => :title
    indexes "LOWER(feature)", :as => :feature
    indexes "LOWER(model)", :as => :model
    set_property :enable_star => true
    set_property :min_prefix_len => 2
    #attributes
  end
           #                                (c)luster 
           #                                (f)ilter 
           #                                (d)escription for groups
           #                                (t)ext for single product description
           #                                (x)compared
           #     db_name           Type     (e)xtra Display
  Features = [%w(price             Continuous  xcfd   ),
              %w(ppm               Continuous  txcfd  ),
              %w(itemwidth         Continuous  txcfd  ),
              %w(paperinput        Continuous  txcfd  ),
              %w(resolutionmax     Continuous  xcfd   ),
              %w(resolution        Categorical t      ),
              %w(brand             Categorical xf     ),
              %w(scanner           Binary      txcf   ),
              %w(printserver       Binary      txcf   )]
                                                   
  ContinuousFeatures = Features.select{|f|f[1] == "Continuous" && f[2].index("c")}.map{|f|f[0]}
  DescFeatures = Features.select{|f|f[2].index("d")}.map{|f|f[0]}
  SingleDescFeatures = Features.select{|f|f[2].index("t")}.map{|f|f[0]}
  ContinuousFeaturesF = Features.select{|f|f[1] == "Continuous" && f[2].index("f")}.map{|f|f[0]}
  BinaryFeatures = Features.select{|f|f[1] == "Binary" && f[2].index("c")}.map{|f|f[0]}
  BinaryFeaturesF = Features.select{|f|f[1] == "Binary" && f[2].index("f")}.map{|f|f[0]}
  CategoricalFeatures = Features.select{|f|f[1] == "Categorical"}.map{|f|f[0]}
  CategoricalFeaturesF = Features.select{|f|f[1] == "Categorical" && f[2].index("f")}.map{|f|f[0]}
  ExtraFeature = Hash[*Features.select{|f|f[2].index("e")}.map{|f|[f[0],true]}.flatten]
  ShowFeatures = %w(brand model ppm paperinput ttp resolution itemwidth itemheight itemlength duplex connectivity papersize scanner printserver platform)
  DisplayedFeatures = Features.select{|f|f[2].index("x")}.map{|f|f[0]}
  ItoF = %w(price itemwidth)
  ValidRanges = { 'itemheight' => [1_00,60_00], 'itemlength' => [1_00,40_00], 'itemwidth' => [1_00,40_00], \
    'ppm' => [2, 70], 'paperinput' => [10,5000], 'ttp' => [4, 50], \
    'resolutionmax' => [600,9600], 'itemweight' => [3_00, 100_00]} #, 'priceint' => [1_00, 20_000_00] }
  MinPrice = 1_00
  MaxPrice = 20_000_00
      
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.select{|f|!f.match(/^minf|maximumfocallength|minimumfocallength$/)}.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),['brand','model'].map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"
  named_scope :valid_and_modelled, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),['brand','model', 'aa_batteries', 'maximumshutterspeed'].map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  def self.urlname
    @urlname ||= name.pluralize.downcase
  end
end

