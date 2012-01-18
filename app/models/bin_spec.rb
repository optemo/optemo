class BinSpec < ActiveRecord::Base
  belongs_to :product
  # Get specs for a single item
  def self.cache_all(p_id)
    CachingMemcached.cache_lookup("BinSpecs#{p_id}") do
      r = select("name, value").where(:product_id => p_id).each_with_object({}){|r, h| h[r.name] = r.value}
    end
  end
  def self.cachemany(p_ids, feat) # Returns numerical (floating point) values only
    CachingMemcached.cache_lookup("BinSpecs#{feat}#{p_ids.join(',').hash}") do
      select("value").where(["product_id IN (?) and name = ?", p_ids, feat]).map(&:value)
    end
  end
  def self.all(feat)
    CachingMemcached.cache_lookup("#{Session.product_type}Bins-#{feat}") do
      select("value").where("product_id IN (select product_id from search_products where search_id = ?) and name = ?", Session.product_type_id, feat).map(&:value)
    end
  end
  def self.count_feat(feat)
   # mycats = Session.search.userdatacats.group_by{|x|x.name}.values
    mycats = Session.search.userdatacats
    myconts = Session.search.userdataconts
    mybins = Session.search.userdatabins.reject{|e|e.name == feat} << BinSpec.new(:name => feat, :value => true)
    #q = Equivalence.no_duplicate_variations(mycats,mybins,myconts,false)
    q = Session.search.count_availables(mybins,mycats,myconts)
    q.group(:eq_id_str).ngroups
    #CachingMemcached.cache_lookup("BinsCount-#{q.to_sql.hash}") do
     # q.count
    #end
  end
end
