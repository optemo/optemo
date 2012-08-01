class BinSpec < ActiveRecord::Base
  belongs_to :product
  
  # Get specs for a single item
  def self.cache_all(p_id)
    CachingMemcached.cache_lookup("BinSpecs#{p_id}") do
      r = select("name, value").where(:product_id => p_id).each_with_object({}){|r, h| h[r.name] = r.value}
    end
  end
  def self.cachemany(p_ids, feat) # Returns numerical (floating point) values only
    CachingMemcached.cache_lookup("BinSpecs#{feat}#{p_ids.join(',')}") do
      select("value").where(["product_id IN (?) and name = ?", p_ids, feat]).map{|x|x.value}
    end
  end
  def self.all(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}Bins-#{feat}") do
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Session.product_type_id, feat).map{|x|x.value}
    end
  end
  def self.cache_group(p_ids) # Returns specs for every product in the list
    CachingMemcached.cache_lookup("BinSpecsGroup#{p_ids.join(',')}") do
      select("product_id, name, value").where(["product_id IN (?)", p_ids]).all
    end
  end
  def self.count_feat(feat)
   Session.search.solr_cached.facet(feat.to_sym).rows.try(:first).try(:count) || 0
  end
end
