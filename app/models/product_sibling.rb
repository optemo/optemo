class ProductSibling < ActiveRecord::Base
  belongs_to :product
  #Returns an array of results: all the sibling ids (sibling product ids) of the given array of product ids
  def self.cachemany(ids)
    CachingMemcached.cache_lookup("ManyProductSiblings#{ids.join(',')}") do
      sibling_hash = {}
      ProductSibling.find(:all, :conditions => ["product_id IN (?) OR sibling_id IN (?)",ids, ids])
      find_all_by_product_id(ids).each do |x|
        if sibling_hash[x.product_id]
          sibling_hash[x.product_id] << x.sibling_id
        else
          sibling_hash[x.product_id] = [x.sibling_id]
        end
        # Now make it symmetrical
        if sibling_hash[x.sibling_id]
          sibling_hash[x.sibling_id] << x.product_id
        else
          sibling_hash[x.sibling_id] = [x.product_id]
        end
      end
      #Product.instock.joins(:product_siblings).where(:product_siblings => {sibling_id: ids}).to_a.each{|x| sibling_hash[x.id] = x.instock}
      sibling_hash
    end
  end
end
