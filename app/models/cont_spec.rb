class ContSpec < ActiveRecord::Base
  belongs_to :product 

  # Get specs for a single item, returns a hash of this format: {"price" => 1.75, "width" => ... }
  def self.cache_all(p_id)
    CachingMemcached.cache_lookup("ContSpecs#{p_id}") do
      select("name, value").where(["product_id = ?", p_id]).all.each_with_object({}){|r, h| h[r.name] = r.value}
    end
  end
  def self.cachemany(p_ids, feat) # Returns numerical (floating point) values only
    CachingMemcached.cache_lookup("ContSpecs#{feat}#{p_ids.join(',').hash}") do
      select("value").where(["product_id IN (?) and name = ?", p_ids, feat]).all.map(&:value)
    end
  end
  
  #Deprecated, don't use this method as there are other methods with similar information
  def self.all
    CachingMemcached.cache_lookup("ContSpecsAll#{Session.product_type_id}") do
      joins("INNER JOIN search_products ON cont_specs.product_id = search_products.product_id").select("search_products.product_id, group_concat(cont_specs.name) AS names, group_concat(cont_specs.value) AS vals").where(:search_products => {:search_id => Session.product_type_id}).group(:product_id).all
    end
  end
  
  # This probably isn't needed anymore, but is a good example of how to do class caching if we want to do it in future.
  def self.featurecache(p_id, feat) 
    @@cs = {} unless defined? @@cs
    p_id = p_id.to_s
    unless @@cs.has_key?(Session.product_type + p_id + feat)
      find_all_by_product_type(Session.product_type).each {|f| @@cs[(Session.product_type + f.product_id.to_s + f.name)] = f}
    end
    @@cs[(Session.product_type + p_id + feat)]
  end
  
  def self.allMinMax(feat)
    mycats = Array(Maybe(Session.search).userdatacats.group_by{|x|x.name}["product_type"])
    q = SearchProduct.fq_categories(mycats).joins("INNER JOIN cont_specs ON cont_specs.product_id = search_products.product_id").where(:cont_specs => {name: feat}).select("cont_specs.value")
    CachingMemcached.cache_lookup("SQL-#{q.to_sql.hash}") do
      all = q.map(&:value).compact
      [all.min,all.max]
    end
  end
  
  def == (other)
     return false if other.nil?
     return value == other.value && product_id == other.product_id #&& name == other.name Not included due to partial db instatiations ie .select("product_ids, values")
  end
  
  private
  
  def self.initial_specs(feat)
    joins("INNER JOIN search_products ON cont_specs.product_id = search_products.product_id").where(:cont_specs => {:name => feat}, :search_products => {:search_id => Session.product_type_id}).select("value").all.map(&:value)
  end

  public
  class << self
    def fq2
      mycats = Session.search.userdatacats.group_by{|x|x.name}.values
      mybins = Session.search.userdatabins
      myconts = Session.search.userdataconts
      res = ContSpec.joins("INNER JOIN (#{Equivalence.no_duplicate_variations(mycats,mybins,myconts,Session.search.sortby).to_sql}) as pids ON pids.product_id = `cont_specs`.`product_id`").products_and_specs.sorting(Session.search.sortby)
      q = res.to_sql
      cached = CachingMemcached.cache_lookup("Products-#{q.hash}") do
        run_query_no_activerecord(q)
      end
      #ComparableSet.from_storage(cached)
      cached.map{|c|ProductAndSpec.from_storage(c)}
    end
  end
    private
  class << self
    def sorting(sortby)
      sortby ||= "utility" #Default sorting
      if sortby =~ /(\w+)_asc/
          sortby = $1
          Session.features['sortby'].select{|f|f.name == sortby}.first.style == 'asc'
          order = "ASC"
      else
          order =  "DESC"
      end
      joins("INNER JOIN cont_specs cont_specs_sort ON cont_specs_sort.product_id = `cont_specs`.product_id").where("cont_specs_sort.name = '#{sortby}'").order("cont_specs_sort.value #{order}")
    end
    
    def products_and_specs
      #This returns product ids along with products spec names and values, to be used in ProductAndSpec
      select("`cont_specs`.`product_id`, group_concat(`cont_specs`.name) AS names, group_concat(`cont_specs`.value) AS vals").group("`cont_specs`.`product_id`")
    end
    
    def run_query_no_activerecord(q)
      #We don't want to store the activerecord here
      tried_once = true
      begin
        result = self.connection.execute(q).to_a
        raise SearchError, "No products match that search criteria for #{Session.product_type}" if result.empty?
      rescue SearchError
        #Check if the initial products are missing
        if SearchProduct.search_id_q.count == 0 && tried_once
          SearchProduct.transaction do
            Product.instock.current_type.map{|product| SearchProduct.new(:product_id => product.id, :search_id => Session.product_type_id)}.each(&:save)
          end
          tried_once = false
          retry
        else
          raise
        end
      end
      result
    end
  end
end
class SearchError < StandardError; end
