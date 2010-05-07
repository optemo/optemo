class CatSpec < ActiveRecord::Base
  belongs_to :product
  
  def self.allSpecs(feat)
    CachingMemcached.cache_lookup("#{$product_type}Cats-#{feat}") do
      id_array = Product.valid.instock.map(&:id)
      find(:all, :select => 'value', :conditions => ["product_id IN (?) and name = ?", id_array, feat]).map(&:value)
    end
  end

end
