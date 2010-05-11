class CatSpec < ActiveRecord::Base
  belongs_to :product
  
  def self.all(feat)
    id_array = Product.valid.instock.map(&:id)
    CachingMemcached.cache_lookup("#{$product_type}Cats-#{feat}#{id_array.join('-').hash}") do
      find(:all, :select => 'value', :conditions => ["product_id IN (?) and name = ?", id_array, feat]).map(&:value).uniq
    end
  end

end
