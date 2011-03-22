class SearchProduct < ActiveRecord::Base
  class << self
    def queryPresent?
      s = Session.search
      return !(s.userdatacats.empty? && s.userdataconts.empty? && s.userdatabins.empty? && s.keyword_search.blank?)
    end
    
    def filterquery
      mycats = Session.search.userdatacats.group_by(&:name).values
      mybins = Session.search.userdatabins
      search_id_q.create_join(mycats,mybins).conts_keywords.cats(mycats).bins(mybins)
    end
    
    def fq2
      mycats = Session.search.userdatacats.group_by(&:name).values
      mybins = Session.search.userdatabins
      myconts = Session.search.userdataconts
      if Session.directLayout
        unless Session.search.sortby == "Price"
          # We order by utility here, the default ("Relevance" or blank sortby term)
          res = search_id_q.select("search_products.product_id, group_concat(cont_specs#{myconts.size}.name) AS names, group_concat(cont_specs#{myconts.size}.value) AS vals").create_join(mycats,mybins,myconts+[[],[]]).conts_keywords.cats(mycats).bins(mybins).where("cont_specs#{myconts.size+1}.name = 'utility'").group("search_products.product_id").order("cont_specs#{myconts.size+1}.value DESC")
        else
          # We order by price here
          res = search_id_q.select("search_products.product_id, group_concat(cont_specs#{myconts.size}.name) AS names, group_concat(cont_specs#{myconts.size}.value) AS vals").create_join(mycats,mybins,myconts+[[],[]]).conts_keywords.cats(mycats).bins(mybins).where("cont_specs#{myconts.size+1}.name = 'price'").group("search_products.product_id").order("cont_specs#{myconts.size+1}.value ASC")
        end
      else
        res = search_id_q.select("search_products.product_id, group_concat(cont_specs#{myconts.size}.name) AS names, group_concat(cont_specs#{myconts.size}.value) AS vals").create_join(mycats,mybins,myconts+[[]]).conts_keywords.cats(mycats).bins(mybins).group("search_products.product_id")
      end
      cached = CachingMemcached.cache_lookup("Products-#{res.to_sql}") do
        specs = Hash.new{|h,k| h[k] = []}
        res.each do |rec|
          names = rec.names.split(",")
          vals = rec.vals.split(",")
          names.each_with_index{|name,i|specs[name] << vals[i].to_f}
        end
        raise SearchError, "No products match that search criteria for #{Session.product_type}" if res.empty?
        specs.default = nil #Clear the array default so that it can be stored in the cache
        p_ids = res.map(&:product_id)
        [specs,p_ids]
      end
      
      ContSpec.by_feat = cached.first
      Session.search.products_size = cached[1].length
      cached[1]
    end
    
    def cat_counts(feat,expanded)
      allcats = Session.search.userdatacats.group_by(&:name)
      mycats = allcats.reject{|id|feat == id}.values
      mybins = Session.search.userdatabins
      table_id = mycats.size
      if expanded
        q = where(:search_id => Product.initial).create_join(mycats+[[feat]],mybins).conts_keywords.bins(mybins).cats(mycats).where(["cat_specs#{table_id}.name = ?", feat]).group("cat_specs#{table_id}.value").order("count(*) DESC")
      else
        q = search_id_q.create_join(mycats+[[feat]],mybins).conts_keywords.bins(mybins).cats(mycats).where(["cat_specs#{table_id}.name = ?", feat]).group("cat_specs#{table_id}.value").order("count(*) DESC")
      end
      CachingMemcached.cache_lookup("Cats-#{q.to_sql}") do
        q.count.merge(Hash[CatSpec.alloptions(feat).map {|x| [x, 0]}]){|k,oldv,newv|oldv}
      end
    end
    
    def bin_count(feat)
      mycats = Session.search.userdatacats.group_by(&:name).values
      mybins = Session.search.userdatabins.reject{|e|e.name == feat} << BinSpec.new(:name => feat, :value => true)
      where(:search_id => Product.initial).create_join(mycats,mybins).conts_keywords.cats(mycats).bins(mybins).count
    end
  end
  private
  class << self
    def search_id_q
      where(:search_id => Session.search.products_search_id)
    end
      
    def create_join(mycats,mybins,myconts = Session.search.userdataconts)
      tables = []
      tables << ["cont_specs"] * myconts.size
      tables << ["cat_specs"] * mycats.size
      tables << ["bin_specs"] * mybins.size
      tables << ["keyword_searches"] if Session.search.keyword_search
      myjoins = []
      tables.map{|type|type.each_with_index{|table,i| myjoins << "INNER JOIN #{table} #{table+i.to_s} ON search_products.product_id = #{table+i.to_s}.product_id"}}
      joins(myjoins.join(" "))
    end
    
    def conts_keywords
      res = []
      Session.search.userdataconts.each_with_index do |d,i|
        res << "cont_specs#{i}.value <= #{d.max+0.00001} and cont_specs#{i}.value >= #{d.min-0.00001} and cont_specs#{i}.name = '#{d.name}'"
      end
      res << "keyword_searches0.keyword = '#{Session.search.keyword_search}'" if Session.search.keyword_search
      where(res.join(" and "))
    end
    
    def cats(mycats)
      res = []
      mycats.each_with_index do |group, i|
        res << ("(" + group.map{|cs| "(cat_specs#{i}.value = '#{cs.value}' and cat_specs#{i}.name = '#{cs.name}')"}.join(" OR ") + ")")
      end
      where(res.join(" and "))
    end
    
    def bins(mybins)
      res = []
      mybins.each_with_index do |d,i|
        res << "bin_specs#{i}.value = #{d.value} and bin_specs#{i}.name = '#{d.name}'"
      end
      where(res.join(" and "))
    end
  end
end
class SearchError < StandardError; end