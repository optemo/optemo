class CatSpec < ActiveRecord::Base
  belongs_to :product
  
  def self.all(feat)
#    id_array = Product.valid.instock.map(&:id)
    id_array = Session.current.search.clusters.map(&:nodes).flatten.map(&:product_id)
    CachingMemcached.cache_lookup("#{$product_type}Cats-#{feat}#{id_array.join('-').hash}") do
      find(:all, :select => 'value', :conditions => ["product_id IN (?) and name = ?", id_array, feat]).map(&:value).uniq
    end
  end

end
