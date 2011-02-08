class TextSpec < ActiveRecord::Base
  def self.cache_all(p_id)
    CachingMemcached.cache_lookup("TextSpecs#{p_id}") do
      select("name, value").where(["product_id = ?", p_id]).each_with_object({}){|r, h| h[r.name] = r.value}
    end
  end
end
