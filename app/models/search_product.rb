class SearchProduct < ActiveRecord::Base
  class << self
    def filterquery
      mycats = Session.current.search.userdatacats.group_by(&:name).values
      mybins = Session.current.search.userdatabins
      search_id_q.create_join(mycats,mybins).conts_keywords.cats(mycats).bins(mybins)
    end
    
    def cat_counts(feat)
      mycats = Session.current.search.userdatacats.group_by(&:name).reject{|id|id == feat}.values
      mybins = Session.current.search.userdatabins
      table_id = mycats.size
      search_id_q.create_join(mycats+[[feat]],mybins).conts_keywords.bins(mybins).cats(mycats).where(["cat_specs#{table_id}.name = ?", feat]).group("cat_specs#{table_id}.value").count
    end
    
    def bin_count(feat)
      mycats = Session.current.search.userdatacats.group_by(&:name).values
      mybins = Session.current.search.userdatabins.reject{|e|e.name == feat} << BinSpec.new(:name => feat, :value => true)
      search_id_q.create_join(mycats,mybins).conts_keywords.cats(mycats).bins(mybins).count
    end
  end
  private
  class << self
    def search_id_q
      where(:search_id => Session.current.search.products_search_id)
    end
      
    def create_join(mycats,mybins)
      tables = []
      s = Session.current.search
      tables << ["cont_specs"] * s.userdataconts.size
      tables << ["cat_specs"] * mycats.size
      tables << ["bin_specs"] * mybins.size
      tables << ["keyword_searches"] if s.keyword_search
      myjoins = []
      tables.map{|type|type.each_with_index{|table,i| myjoins << "INNER JOIN #{table} #{table+i.to_s} ON search_products.product_id = #{table+i.to_s}.product_id"}}
      joins(myjoins.join(" "))
    end
    
    def conts_keywords
      res = []
      Session.current.search.userdataconts.each_with_index do |d,i|
        res << "cont_specs#{i}.value <= #{d.max+0.00001} and cont_specs#{i}.value >= #{d.min-0.00001} and cont_specs#{i}.name = '#{d.name}'"
      end
      res << "keyword_searches0.keyword = '#{Session.current.search.keyword_search}'" if Session.current.search.keyword_search
      where(res.join(" and "))
    end
    
    def cats(mycats)
      res = []
      mycats.each_with_index do |group, i|
        res << group.map{|cs| "(cat_specs#{i}.value = '#{cs.value}' and cat_specs#{i}.name = '#{cs.name}')"}.join(" OR ")
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
