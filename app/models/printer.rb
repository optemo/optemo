class Printer < ActiveRecord::Base
  include ProductProperties
  #Ultrasphinx field selection
  define_index do
    #fields
    indexes title
    indexes feature
    indexes :model
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
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.select{|f|!f.match(/^minf|maximumfocallength|minimumfocallength$/)}.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),['brand','model'].map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"
  named_scope :valid_and_modelled, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),['brand','model', 'aa_batteries', 'maximumshutterspeed'].map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  def self.urlname
    @urlname ||= name.pluralize.downcase
  end
end

