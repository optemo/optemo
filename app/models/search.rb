  # -*- coding: utf-8 -*-
require 'sunspot_spellcheck'
require 'will_paginate/array'

class Search < ActiveRecord::Base
  attr_writer :userdataconts, :userdatacats, :userdatabins, :products_size
  attr_accessor :expanded, :collation, :col_emp_result, :num_result, :validated_keyword, :specs, :siblings, :sibling_assocs, :bundles, :bundle_assocs
  
  self.per_page = 18 #for will_paginate
  
  def solr_cached(opt = nil)
    @solr_cached = nil if opt #Clear cache
    @solr_cached ||= solr_search(opt || {})
  end
  
  def solr_search(opt = {})
    mybins = opt[:mybins] || userdatabins
    mycats = opt[:mycats] || userdatacats
    myconts = opt[:myconts] || userdataconts
    search_term = opt[:searchterm] || @validated_keyword
    
    filtering = Product.search do
      if search_term
        phrase = search_term.downcase.gsub(/\s-/,'').to_s
        fulltext phrase do
          # Example of how to do boost, if we wish to use boosting in future.
          #filters_bins.each do |b|
          #  boost(30) {with(b.name.to_sym, b.value)}
          #end
        end
      end  
      
      # sort by: either selected sortby or by default, the first of the sortby facets set in the session
      type, direction = sortby.try(:split, "_")
      if type.nil?
        type = Session.features['sortby'].first.name
        direction = Session.features['sortby'].first.style
      end
      order_by(type.to_sym, direction.to_sym)
      order_by(:utility, :desc) #Break ties with heuristic utility (used as utility if lr_utility is nil)
          
      cat_filters = {} #Used for faceting exclude so that the counts are right
      mycats.group_by{|x|x.name}.each_pair do |name, group|
        cat_filters[name] = any_of do  #disjunction inside the category part
          group.each do |cats|
            if cats.name == "product_type"
              with :product_type, ProductCategory.get_leaves(cats.value)
            else
              with cats.name.to_sym, cats.value
            end
          end
        end
      end
      #The default is a conjunction for all the items
      mybins.each do |bins|
        with bins.name.to_sym, bins.value
      end
      cont_filters = {}
      myconts.group_by{|x|x.name}.each_pair do |name, group|
        cont_filters[name] = any_of do  #disjunction inside the category part
          group.each do |conts|
            with conts.name.to_sym, conts.min||0..conts.max||1000000
          end
        end
      end
      
      spellcheck :count => 4
      with :instock, 1
      paginate :page=> page, :per_page => Search.per_page
      group :eq_id_str do 
        ngroups  # includes the number of groups that have matched the query
        facet #Solr patch 2898, allows only one count per group
        #truncate # facet counts are based on the most relevant document of each group matching the query
        order_by(:isBundleCont, :asc) # Make sure products instead of bundles are the representative
        order_by(type.to_sym, direction.to_sym) # Choose rep by sorting order
        order_by(:utility, :desc) #Break ties with heuristic utility 
      end
      unless search_term
        with :product_type, Session.landing_page_leaves
      end
      (Session.features["filter"] || []).each do |f|
          if f.feature_type == "Continuous"
            facet f.name.to_sym, sort: :index, exclude: cont_filters[f.name], limit: -1
          elsif f.feature_type == "Binary"
            facet f.name.to_sym
          elsif f.feature_type == "Categorical" 
            if f.name == "product_type"
              facet :product_type, exclude: cat_filters[f.name]
              facet :first_ancestors, exclude: cat_filters[f.name]
              facet :second_ancestors, exclude: cat_filters[f.name]
            else
              facet f.name.to_sym, exclude: cat_filters[f.name]
            end
          end
      end
    end
  end
  
  def solr_products_count
    mybins = userdatabins
    mycats = userdatacats
    myconts = userdataconts
    search_term = keyword_search
    #puts "\nmybins: #{mybins}\nmycats: #{mycats}\nmyconts: #{myconts}\n"
    filtering = Product.search do
      if search_term
        phrase = search_term.downcase.gsub(/\s-/,'').to_s
        fulltext phrase
      end
      
      cat_filters = {} #Used for faceting exclude so that the counts are right
      mycats.group_by(&:name).each_pair do |name, group|
        cat_filters[name] = any_of do  #disjunction inside the category part
          group.each do |cats|
            if cats.name == "product_type"
              leaves = ProductCategory.get_leaves(cats.value)
              with :product_type, leaves  
            else
              with cats.name.to_sym, cats.value
            end
          end
        end
      end
      
      #The default is a conjunction for all the items
      mybins.each do |bins|
        with bins.name.to_sym, bins.value
      end
      cont_filters = {}
      myconts.group_by(&:name).each_pair do |name, group|
        cont_filters[name] = any_of do  #disjunction inside the category part
          group.each do |conts|
            with conts.name.to_sym, conts.min||0..conts.max||1000000
          end
        end
      end
      #myconts.each do |conts|
      #  with (conts.name.to_sym), conts.min||0..conts.max||1000000
      #end
      
      with :instock, 1
      group :eq_id_str do 
        ngroups  # includes the number of groups that have matched the query
        facet #Solr patch 2898, allows only one count per group
        #truncate # facet counts are based on the most relevant document of each group matching the query
      end
      if (!search_term)
        with :product_type, Session.product_type_leaves
      end
      # Counting product type results
      f_name = "product_type"
      facet :product_type, exclude: cat_filters[f_name]
      facet :first_ancestors, exclude: cat_filters[f_name]
      facet :second_ancestors, exclude: cat_filters[f_name]
    end
  end
  
  def userdataconts
    @userdataconts ||= Userdatacont.find_all_by_search_id(id)
  end
  
  def userdatacats
    @userdatacats ||= Userdatacat.find_all_by_search_id(id)
  end
  
  def userdatabins
    @userdatabins ||= Userdatabin.find_all_by_search_id(id)
  end
  
  def paginated_products #set the paginated_products
    unless @paginated_products
      products
    end
    @paginated_products
  end
 
  def products_size
    unless @products_size
      products
    end
    @products_size     
  end

  def validated_keyword
    unless @validated_keyword
      products
    end
    @keyword
  end  

  def products
    @validated_keyword = keyword_search
    res = grouping(solr_cached)
    @num_result = solr_cached.group(:eq_id_str).ngroups
    
    if (keyword_search)
      @collation = solr_cached.collation if solr_cached.collation !=nil
      #Redo search with spelling correction
      if (@collation)
        solr_col= solr_search(searchterm: @collation)
        res_col = grouping(solr_col)
        if (res_col.empty?)
          @col_emp_result = true
        end
      end
    end
    
    #Only use the collation if the first results are empty & it's not empty
    if (res.empty? && res_col && !res_col.empty?)
      res = res_col
      @solr_cached = solr_col
      @validated_keyword = @collation
    end
    
    @products_size = solr_cached.group(:eq_id_str).ngroups
    @paginated_products = Sunspot::Search::PaginatedCollection.new res, page||1, Search.per_page,@products_size
  end
  
  def products_landing
    @landing_products ||= CachingMemcached.cache_lookup("FeaturedProducts(#{Session.product_type}") do
      CatSpec.joins("INNER JOIN `bin_specs` ON `cat_specs`.product_id = `bin_specs`.product_id").where(bin_specs: {name: "featured"}, cat_specs: {name: "product_type", value: Session.product_type_leaves}).map{|x|x.product_id}
    end
  end

  # This is the hash we want to embed in the page (and which in turn will be displayed in the address bar).
  # For the landing page, we want no hash displayed in the address bar.
  def hash_to_embed
    if not self.initial?
      self.params_hash
    else
      ""
    end
  end
  
  def initialize(p={}, opt=nil)
    super({})
    self.initial = (not p[:landing].nil?)
    if not p[:keyword].nil? and not p[:keyword].blank?
      self.keyword_search = p[:keyword]
    end
    self.page = p[:page]
    self.sortby = p[:sortby]
    self.params_hash = p[:params_hash]

    @userdataconts = []
    @userdatabins = []
    @userdatacats = []
    createFeatures(p[:filters])
  end
  
  after_save do
    #Save user filters as well
    (userdataconts+userdatabins+userdatacats).each do |d|
      d.search_id = id
      d.save
    end
  end
 
  def createFeatures(p)
    #Continuous Features
    r = /(?<min>[\d.]*);(?<max>[\d.]*)/
    Maybe(p[:continuous]).each_pair do |k,v|
      v.split("*").each do |cont|
        if res = r.match(cont)
          @userdataconts << Userdatacont.new({:name => k, :min => res[:min], :max => res[:max]})
        end
      end
    end
    
    #Binary Features
    Maybe(p[:binary]).each_pair do |k,v|
      #Handle false booleans
      if v != '0'
        @userdatabins << Userdatabin.new({:name => k, :value => v})
      end
    end
    
    #Categorical Features
    Maybe(p[:categorical]).each_pair do |k,v|
      v.split("*").each do |cat|
        @userdatacats << Userdatacat.new({:name => k, :value => cat})
      end
    end
    
    @expanded = p[:expanded].try(:keys)
  end
  
  # Takes array of available facets and prunes filters which do not
  # match one of the available facets.
  def prune_filters(facets) 
    [[userdatacats, "Categorical"], [userdataconts, "Continuous"], [userdatabins, "Binary"]].each do |filters, filter_type|
      to_remove = []
      filters.each do |filter|
        matching_facet = facets.find do |facet| 
          facet.feature_type == filter_type and facet.name == filter.name and facet.active and facet.used_for == "filter" 
        end
        if matching_facet.nil? 
          to_remove << filter
        end
      end
      to_remove.each { |filter| filters.delete(filter) }
    end
  end
  
  private 
  
  def grouping(things)
    # By using .hits, we can get just the ids instead of getting the results. See Solr documentation
    res = things.group(:eq_id_str).groups.inject([]) do |res, g|
      res << g.hits.first.primary_key.to_i
    end
    Product.cachemany(res)
  end

end

