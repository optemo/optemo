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
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Session.product_type_id, feat).map(&:value)
    end
  end
  def self.alloptions(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}Cats-#{feat}-options") do
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Session.product_type_id, feat).map(&:value).uniq
    end
  end
  
  def self.count_feat(feat,level=nil)
    if feat == "product_type" && level == 1
      feat= "first_ancestors"
    elsif feat=="product_type" && level == 2
      feat= "second_ancestors"
    end
    Session.search.solr_cached.facet(feat.to_sym).rows.inject({}) do |q,r|
      q[r.value] = r.count
      q
    end
  end
  
  def self.count_current(feat)
    # uses a small fresh solr search for the purpose of getting counts needed before the longer search gets executed
    Session.search.solr_products_count.facet(feat.to_sym).rows.inject({}) do |q,r|
      q[r.value] = r.count
      q
    end
  end
  
  def self.order(feat)
    q = Facet.where(used_for: "ordering", product_type: Session.product_type, feature_type: feat)
    CachingMemcached.cache_lookup("CatOrder#{q.to_sql.hash}") do
      q.inject({}){|h,f| h[f.name] = f.value; h}
    end
  end
end
