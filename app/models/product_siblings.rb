class ProductSiblings < ActiveRecord::Base
   belongs_to :product
   #include itself and its siblings
  def self.cache_ids_and_imgsurl(id, name)
    CachingMemcached.cache_lookup("ProductSiblings#{id}") do
      select("sibling_id, value").where(["product_id=(?) and name=(?)", id, name])
    end
  end  
end