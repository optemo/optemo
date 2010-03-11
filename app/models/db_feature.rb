class DbFeature < ActiveRecord::Base
  def self.featurecache(feat) 
    # Caching is better using class variable; do not change to memcached.
    # Hash key must be based on model name (camera/printer), region, and feature name together to guarantee uniqueness.
    unless defined? @@dbf
      @@dbf = {}
    end
    unless @@dbf.has_key?($model.name + $region + feat)
      find_all_by_product_type_and_region($model.name,$region).each {|f| @@dbf[($model.name + $region + f.name)] = f}
    end
    @@dbf[($model.name + $region + feat)]
  end
end
