class Laptop < ActiveRecord::Base
  include ProductProperties
  def self.productcache(id) 
    # Caching is better using class variable; do not change to memcached.
    # Hash key must be based on model name (flooring/printer), region, and feature name together to guarantee uniqueness.
    unless defined? @@laptops
      @@laptops = {}
    end
    unless @@laptops.has_key?('Laptop' + $region + id.to_s)
      @@laptops[('Laptop' + $region + id.to_s)] = Session.current.findCachedProduct(id) #Needs to be fixed or removed
    end
    @@laptops[('Laptop' + $region + id.to_s)]
  end
  
  has_many :laptop_nodes
  define_index do
    #fields
    indexes "LOWER(title)", :as => :title
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
  Features = [%w(price                Continuous  cf    ),
              %w(hd                   Continuous  tcf    ),
              %w(ram                  Continuous  tcf    ),
              %w(screensize           Continuous  tcf    ),
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
  ShowFeatures = %w(brand pricestr hd ram screensize)
  DisplayedFeatures = %w(pricestr brand hd ram screensize)
  ItoF = %w(price)
  ValidRanges = { }
  MinPrice = 1_00
  MaxPrice = 100_000_00
  
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' >= 0'}.join(' AND '),BinaryFeatures.map{|i|i+' IS NOT NULL'}.join(' AND '),['brand'].map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  def self.urlname
    @urlname ||= name.pluralize.downcase
  end
end
