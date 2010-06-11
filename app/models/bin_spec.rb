class BinSpec < ActiveRecord::Base
  belongs_to :product
  def self.cache(p_id, feat)
    CachingMemcached.cache_lookup("BinSpec#{feat}#{p_id}") do
      r = find_by_product_id_and_name(p_id, feat)
      r.value if r
    end
  end
end
