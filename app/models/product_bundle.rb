class ProductBundle < ActiveRecord::Base
  belongs_to :product

  def self.cachemany(ids)
    CachingMemcached.cache_lookup("ManyProductBundles#{ids.join(',')}") do
      bundle_hash = {}
      find_all_by_product_id(ids).each do |x|
      #Product.instock.joins(:product_bundles).where(:product_bundles => {product_id: ids}).to_a.each{|x| bundle_hash[x.id] = x.instock}
        if bundle_hash[x.product_id]
          bundle_hash[x.product_id] << x.bundle_id
        else
          bundle_hash[x.product_id] = [x.bundle_id]
        end
      end
      bundle_hash
    end
  end
end
