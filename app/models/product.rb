class Product < ActiveRecord::Base
  has_many :nodes
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  
  #This can called with a single id or an array of ids
  def self.cached(ids)
    CachingMemcached.cache_lookup("Product#{ids}"){find(ids)}
  end
  
  named_scope :instock, :conditions => {:instock => true}
  named_scope :valid, :conditions => \
  ($Continuous["filter"].map{|f|"id in (select product_id from cont_specs where value > 0 and name = '#{f}')"}+\
  $Binary["filter"].map{|f|"id in (select product_id from bin_specs where value IS NOT NULL and name = '#{f}')"}+\
  $Categorical["filter"].map{|f|"id in (select product_id from cat_specs where value IS NOT NULL and name = '#{f}')"}).join(" and ")
end
