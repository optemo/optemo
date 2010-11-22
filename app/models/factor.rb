class Factor < ActiveRecord::Base
  # Gets the precalculated factors, fetching them if they don't exist.
  def self.cachemany_with_ids(p_ids, feat)
    CachingMemcached.cache_lookup("Factors#{feat}#{p_ids.join(',').hash}") do
      select("product_id, value").where(["product_id IN (?) and cont_var = ?", p_ids, feat]).all
    end
  end
  # Using class caching instead, per product_id. Not used at the moment.
  def self.factors(productid)
    unless defined? @@prefetched_factors
      @@prefetched_factors = {}
      Factor.find_all_by_product_type($model.name).compact.each {|f| @@prefetched_factors[f.product_id] = f}
    end
    @@prefetched_factors[productid]
  end
end
