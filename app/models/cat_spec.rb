class CatSpec < ActiveRecord::Base
  belongs_to :product
  
  def self.allSpecs(feat)
    CachingMemcached.cache_lookup("#{$product_type}Cats-#{feat}") do
      id_array = Product.valid.instock.map{|p| p.id }
      ContSpec.cachemany(id_array, feat)
    end
  end

end
