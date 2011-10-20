class Equivalence < ActiveRecord::Base
  class << self
    def all_count
      CachingMemcached.cache_lookup("AllCount-#{Session.product_type_id}") do
        search_id_q.joins("INNER JOIN search_products ON search_products.product_id = `equivalences`.product_id").select("DISTINCT eq_id").count
      end
    end
    
    def no_duplicate_variations(mycats,mybins,myconts,sortby)
      res = search_id_q.joins("INNER JOIN search_products ON search_products.product_id = `equivalences`.product_id").create_join(mycats,mybins,myconts).conts(myconts).cats(mycats).bins(mybins)
      if sortby == false
        res.select("DISTINCT eq_id")
      else
        res.select_part.group("eq_id")
      end
    end
  end
  private
  class << self
    def search_id_q
      where(search_products: {:search_id => Session.product_type_id})
    end
    def create_join(mycats,mybins,myconts = Maybe(Session.search).userdataconts)
      tables = []
      tables << ["cont_specs"] * myconts.size
      tables << ["cat_specs"] * mycats.size
      tables << ["bin_specs"] * mybins.size
      myjoins = []
      tables.map{|type|type.each_with_index{|table,i| myjoins << "INNER JOIN #{table} #{table+i.to_s} ON search_products.product_id = #{table+i.to_s}.product_id"}}
      joins(myjoins.join(" "))
    end
    
    def conts(myconts)
      res = []
      myconts.each_with_index do |d,i|
        res << "cont_specs#{i}.value <= #{d.max+0.00001}" unless d.max.blank?
        res << "cont_specs#{i}.value >= #{d.min-0.00001}" unless d.min.blank?
        res << "cont_specs#{i}.name = '#{d.name}'"
      end
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
    
    def select_part(grouping_table_id = false)
      if grouping_table_id
        select("search_products.product_id, group_concat(cont_specs#{grouping_table_id}.name) AS names, group_concat(cont_specs#{grouping_table_id}.value) AS vals")
      else
        select("search_products.product_id")
      end
    end
  end
end