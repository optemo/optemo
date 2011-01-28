class ProductSiblings < ActiveRecord::Base
   belongs_to :product
   #include itself and its siblings
  def self.cache_ids_and_color(id, name)
    all_prods = []
    CachingMemcached.cache_lookup("ProductSiblings#{id}") do
      ids = select("sibling_id").where(["product_id=(?) and name=(?)", id, name]).map(&:sibling_id)
      select("product_id, value").where(["product_id IN (?) and name=(?)", ids, name])
    end
  end  
end