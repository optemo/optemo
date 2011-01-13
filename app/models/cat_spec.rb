class CatSpec < ActiveRecord::Base
  belongs_to :product
  
  # Get specs for a single item and single feature -- this is deprecated
  #  def self.cache(p_id, feat)
  #    CachingMemcached.cache_lookup("CatSpec#{feat}#{p_id}") do
  #      r = find_by_product_id_and_name(p_id, feat)
  #      r.value if r
  #    end
  #  end

  # Get specs for a single item
  def self.cache_all(p_id)
    CachingMemcached.cache_lookup("CatSpecs#{p_id}") do
      select("name, value").where("product_id = ?", p_id).each_with_object({}){|r, h| h[r.name] = r.value}
    end  
  end

  def self.cachemany(p_ids, feat) # Returns different values 
    CachingMemcached.cache_lookup("CatSpecs#{feat}#{p_ids.join(',').hash}") do
      select("value").where(["product_id IN (?) and name = ?", p_ids, feat]).map(&:value)
    end
  end
  def self.all(feat)
    CachingMemcached.cache_lookup("#{Session.current.product_type}Cats-#{feat}") do
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Product.initial, feat).map(&:value)
    end
  end
end
