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
  
  def self.count_feat(feat,includezeros = false,s = Session.search)
    mycats = s.userdatacats.group_by{|x|x.name}.reject{|id|feat == id}.values
    mybins = s.userdatabins
    myconts = s.userdataconts
    q = Equivalence.no_duplicate_variations(mycats,mybins,myconts,false).joins("INNER JOIN cat_specs cat_count ON cat_count.product_id = `equivalences`.product_id").where(["cat_count.name = ?", feat]).group("cat_count.value").order("count(*) DESC")
    CachingMemcached.cache_lookup("CatsCount(#{includezeros.to_s})-#{q.to_sql.hash}") do
      if includezeros
        q.count.merge(Hash[CatSpec.alloptions(feat).map {|x| [x, 0]}]){|k,oldv,newv|oldv}
      else
        q.count
      end
    end
  end
end
