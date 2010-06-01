class CatSpec < ActiveRecord::Base
  belongs_to :product
  
  def self.cache(p_id, feat)
    CachingMemcached.cache_lookup("CatSpec#{feat}#{p_id}") do
      r = find_by_product_id_and_name(p_id, feat)
      r.value if r
    end
  end
  
  def self.cachemany(p_ids, feat)
    CachingMemcached.cache_lookup("CatSpecs#{feat}#{p_ids.join.hash}") do
      find(:all, :select => 'value', :conditions => ["product_id IN (?) and name = ?", p_ids, feat]).map(&:value)
    end
  end
  
  def self.all(feat)
    CachingMemcached.cache_lookup("#{$product_type}Cats-#{feat}") do
      id_array = Product.valid.instock.map(&:id)
      find(:all, :select => 'value', :conditions => ["product_id IN (?) and name = ?", id_array, feat]).map(&:value).uniq
    end
  end

end
