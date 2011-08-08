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
    
    def fq2_landing(s) 
          mycats = Session.search.userdatacats.group_by(&:name).values
          mybins = Session.search.userdatabins
          myconts = Session.search.userdataconts
          res = []
          order =  "DESC"
           if s=='featured'
               #mybins = [Userdatabin.new({:name => 'hero', :value => 1})]
               #res << search_id_q.create_join(mycats,mybins).conts_keywords.cats(mycats).bins(mybins)#.where("product_type=\'#{Session.product_type}\'")
               mybins = [Userdatabin.new({:name => 'featured', :value => 1})]
               res << search_id_q.create_join(mycats,mybins).conts_keywords.cats(mycats).bins(mybins)#.where("product_type=\'#{Session.product_type}\'") 
           else
               res << search_id_q.select("search_products.product_id, group_concat(cont_specs#{myconts.size}.name) AS names, group_concat(cont_specs#{myconts.size}.value) AS vals").create_join(mycats,mybins,myconts+[[],[]]).conts_keywords.cats(mycats).bins(mybins).where("cont_specs#{myconts.size+1}.name = '#{s}'").group("search_products.product_id").order("cont_specs#{myconts.size+1}.value #{order}")[0...18] 
           end      
          res.flatten
      end    

      def find_hero
        mycats = Session.search.userdatacats.group_by(&:name).values
        mybins = Session.search.userdatabins
        myconts = Session.search.userdataconts  
        res = []  
        mybins = [Userdatabin.new({:name => 'hero', :value => 1})]
        res << search_id_q.create_join(mycats,mybins).conts_keywords.cats(mycats).bins(mybins)#.where("product_type=\'#{Session.product_type}\'")
        res.flatten.first   
      end
            
      def fq2
        sortby= Session.search.sortby
        mycats = Session.search.userdatacats.group_by(&:name).values
        mybins = Session.search.userdatabins
        myconts = Session.search.userdataconts
        if Session.directLayout
          unless sortby == "Price"
            # We order by utility here, the default ("Relevance" or blank sortby term)
            res = search_id_q.select("search_products.product_id, group_concat(cont_specs#{myconts.size}.name) AS names, group_concat(cont_specs#{myconts.size}.value) AS vals").create_join(mycats,mybins,myconts+[[],[]]).conts_keywords.cats(mycats).bins(mybins).where("cont_specs#{myconts.size+1}.name = 'utility'").group("search_products.product_id").order("cont_specs#{myconts.size+1}.value DESC")
          else
            # We order by price here
            res = search_id_q.select("search_products.product_id, group_concat(cont_specs#{myconts.size}.name) AS names, group_concat(cont_specs#{myconts.size}.value) AS vals").create_join(mycats,mybins,myconts+[[],[]]).conts_keywords.cats(mycats).bins(mybins).where("cont_specs#{myconts.size+1}.name = 'price'").group("search_products.product_id").order("cont_specs#{myconts.size+1}.value ASC")
          end
        else
            if sortby.nil? || sortby == "relevance" 
                res = search_id_q.select("search_products.product_id, group_concat(cont_specs#{myconts.size}.name) AS names, group_concat(cont_specs#{myconts.size}.value) AS vals").create_join(mycats,mybins,myconts+[[],[]]).conts_keywords.cats(mycats).bins(mybins).where("cont_specs#{myconts.size+1}.name = 'utility'").group("search_products.product_id").order("cont_specs#{myconts.size+1}.value DESC")
            else    
                if sortby.include?("_high")  
                     order = "ASC"
                     sortby = "saleprice_factor"  # this should be rewritten
                else
                     order =  "DESC"    
                end     
                res = search_id_q.select("search_products.product_id, group_concat(cont_specs#{myconts.size}.name) AS names, group_concat(cont_specs#{myconts.size}.value) AS vals").create_join(mycats,mybins,myconts+[[],[]]).conts_keywords.cats(mycats).bins(mybins).where("cont_specs#{myconts.size+1}.name = '#{sortby}'").group("search_products.product_id").order("cont_specs#{myconts.size+1}.value #{order}")
             end
         end
        q = res.to_sql
        cached = CachingMemcached.cache_lookup("Products-#{q.hash}") do
          #We don't want to store the activerecord here
          tried_once = true
          begin
            result = self.connection.execute(q).to_a
            raise SearchError, "No products match that search criteria for #{Session.product_type}" if result.empty?
          rescue SearchError
            #Check if the initial products are missing
            if search_id_q.count == 0 && tried_once
              initial_products_id = Product.initial
              SearchProduct.transaction do
                Product.instock.current_type.map{|product| SearchProduct.new(:product_id => product.id, :search_id => initial_products_id)}.each(&:save)
              end
              tried_once = false
              retry
            else
              raise
            end
          end
          result
        end
        #ComparableSet.from_storage(cached)
        cached.map{|c|ProductAndSpec.from_storage(c)}
      end
    
    def cat_counts(feat,expanded,includezeros = false,s = Session.search)
      allcats = s.userdatacats.group_by(&:name)
      mycats = allcats.reject{|id|feat == id}.values
      mybins = s.userdatabins
      table_id = mycats.size
      if expanded
        q = where(:search_id => Product.initial).create_join(mycats+[[feat]],mybins,s.userdataconts,s).conts_keywords(s).bins(mybins).cats(mycats).where(["cat_specs#{table_id}.name = ?", feat]).group("cat_specs#{table_id}.value").order("count(*) DESC")
      else
        q = search_id_q.create_join(mycats+[[feat]],mybins,s.userdataconts,s).conts_keywords(s).bins(mybins).cats(mycats).where(["cat_specs#{table_id}.name = ?", feat]).group("cat_specs#{table_id}.value").order("count(*) DESC")
      end
      CachingMemcached.cache_lookup("CatsCount(#{includezeros.to_s})-#{q.to_sql.hash}") do
        if includezeros
          q.count.merge(Hash[CatSpec.alloptions(feat).map {|x| [x, 0]}]){|k,oldv,newv|oldv}
        else
          q.count
        end
      end
    end
    
    def bin_count(feat)
      mycats = Session.search.userdatacats.group_by(&:name).values
      mybins = Session.search.userdatabins.reject{|e|e.name == feat} << BinSpec.new(:name => feat, :value => true)
      q = where(:search_id => Product.initial).create_join(mycats,mybins).conts_keywords.cats(mycats).bins(mybins)
      CachingMemcached.cache_lookup("BinsCount-#{q.to_sql.hash}") do
        q.count
      end
    end
  end
  private
  class << self
    def search_id_q
      where(:search_id => Product.initial)
    end
      
    def create_join(mycats,mybins,myconts = Session.search.userdataconts,s=Session.search)
      tables = []
      tables << ["cont_specs"] * myconts.size
      tables << ["cat_specs"] * mycats.size
      tables << ["bin_specs"] * mybins.size
      tables << ["keyword_searches"] if s.keyword_search
      myjoins = []
      tables.map{|type|type.each_with_index{|table,i| myjoins << "INNER JOIN #{table} #{table+i.to_s} ON search_products.product_id = #{table+i.to_s}.product_id"}}
      joins(myjoins.join(" "))
    end
    
    def conts_keywords(s=Session.search)
      res = []
      s.userdataconts.each_with_index do |d,i|
        res << "cont_specs#{i}.value <= #{d.max+0.00001} and cont_specs#{i}.value >= #{d.min-0.00001} and cont_specs#{i}.name = '#{d.name}'"
      end
      res << "keyword_searches0.keyword = '#{Session.search.keyword_search}'" if s.keyword_search
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