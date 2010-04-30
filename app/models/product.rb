class Product < ActiveRecord::Base
  has_many :nodes
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  
  #This can called with a single id or an array of ids
  def self.cached(ids)
    CachingMemcached.cache_lookup("Product#{ids}"){find(ids)}
  end
  
  
  #named_scope :valid, :conditions => $config["BinaryFeaturesF"].map{|i|i+' > 0'}
end
