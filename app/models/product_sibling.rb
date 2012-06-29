class ProductSibling < ActiveRecord::Base
  belongs_to :product
  #Returns an array of results: all the sibling ids (sibling product ids) of the given array of product ids
  def self.cachemany(ids)
    CachingMemcached.cache_lookup("ManyProductSiblings#{ids.join(',')}") do
      sibling_hash = {}
      find_all_by_product_id(ids).each do |x|
        if sibling_hash[x.product_id]
          sibling_hash[x.product_id] << x.sibling_id
        else
          sibling_hash[x.product_id] = [x.sibling_id]
        end
      end
      #Product.instock.joins(:product_siblings).where(:product_siblings => {sibling_id: ids}).to_a.each{|x| sibling_hash[x.id] = x.instock}
      sibling_hash
    end
  end
end
