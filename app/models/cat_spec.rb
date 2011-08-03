class CatSpec < ActiveRecord::Base
  belongs_to :product

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
    CachingMemcached.cache_lookup("#{Session.product_type}Cats-#{feat}") do
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Product.initial, feat).map(&:value)
    end
  end
  def self.alloptions(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}Cats-#{feat}-options") do
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Product.initial, feat).map(&:value).uniq
    end
  end

  def self.colors_en_fr
    colors = {}
    colors_spec = CatSpec.where("product_type=? and name=?", Session.product_type, 'color')
    colors_spec.each do |spec|
      color_fr = CatSpec.where("product_id=? and name=?", spec.product_id, 'color_fr').first
      if color_fr
        colors[spec.value] = color_fr.value
      end
    end
    colors
  end
end
