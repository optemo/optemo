  # -*- coding: utf-8 -*-
require 'sunspot_spellcheck'
require 'will_paginate/array'

class Search < ActiveRecord::Base
  attr_reader :expanded
  attr_writer :userdataconts, :userdatacats, :userdatabins, :parentcats, :products_size, :filters_cats, :filters_conts, :filters_bins
  attr_accessor :collation, :col_emp_result, :num_result, :validated_keyword, :old_keyword, :specs, :siblings, :sibling_assocs, :bundles, :bundle_assocs
  
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
          #boost() 
          #  function do
          #    for i in (0..size-1)
          #      a = sum(filters_bins[i].name.to_sym, a)
          #    end
          #  end
          # )
          filters_bins.each do |b|
            boost(30) {with(b.name.to_sym, b.value)}
          end
          
          filters_cats.each do |ca|
            boost(20) {with ca.name, ca.value}
          end
          
          filters_conts.each do |c|
            boost(10) { with (c.name.to_sym), c.min||0..c.max||100000}   
          end
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
        order_by(:isBundleCont, :asc)
      end
      if (!search_term)
        with :product_type, Session.product_type_leaves
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
  def parentcats
    @parentcats ||=[]
  end
  
  def parentconts
    @parentconts ||=[]
  end  
  
  def filters_cats
    @filters_cats ||= []
  end
  
  def filters_conts
    @filters_conts ||= []
  end
  
  def filters_bins
    @filters_bins ||= []
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
    #puts "hashed_product_type #{Session.product_type}"
    if (keyword_search)
      things = solr_cached
      res = grouping(things)
      
      @num_result = things.group(:eq_id_str).ngroups
      @collation = things.collation if things.collation !=nil
      #puts "collation_term #{@collation}"
      res_col=[]
      if (@collation)
        things_col= solr_search(searchterm: @collation)
        res_col = grouping(things_col)
        if (res_col.empty?)
          @col_emp_result = true
        end
      end
      if (res.empty?)
        unless (res_col.empty?)
          products_list(res_col,things_col.group(:eq_id_str).ngroups)
          @solr_cached = things_col
          @validated_keyword = @collation
        else
          products_list(res,things.group(:eq_id_str).ngroups) 
        end
      else
        products_list(res,things.group(:eq_id_str).ngroups)  
      end
    else
      things = solr_cached
      products_list( grouping(things), things.group(:eq_id_str).ngroups)
    end
  end
  
  def grouping(things)
    res=[]
    # By using .hits, we can get just the ids instead of getting the results. See Solr documentation
    things.group(:eq_id_str).groups.each do |g|
      res << g.hits.first.primary_key.to_i
    end
    Product.cachemany(res)
  end

  def products_list(things, total) #paginate products through sunspot pagination
    @products_size = total    
    @paginated_products = Sunspot::Search::PaginatedCollection.new things, page||1, Search.per_page,total
   # @paginated_products.each do |p|
   #   puts "p.product_type #{p.id}"
   # end
   end

  def products_landing
    @landing_products ||= CachingMemcached.cache_lookup("FeaturedProducts(#{Session.product_type}") do
      CatSpec.joins("INNER JOIN `bin_specs` ON `cat_specs`.product_id = `bin_specs`.product_id").where(bin_specs: {name: "featured"}, cat_specs: {name: "product_type", value: Session.product_type_leaves}).map{|x|x.product_id}
    end
  end
  
  def initialize(p={}, opt=nil)
    super({})
    #Set parent id
    self.parent_id = CGI.unescape(p[:parent]).unpack("m")[0].to_i unless p[:parent].blank?
    unless p[:action_type] == "allproducts" || p[:action_type] == "landing" #Exception for initial clusters
      old_search = Search.find_by_id(self.parent_id)
    end
    # If there is a sort method to keep from last time, move it across
    self.sortby = old_search[:sortby] if old_search && old_search[:sortby]
    # save the old_keyword 
    @old_keyword = old_search.keyword_search if old_search
    #puts "old_keyword_init #{@old_keyword}"
    case p[:action_type]
    when "allproducts"
      #Initial load of the homepage
      self.initial = false
      @userdataconts = []
      @userdatabins = []
      @userdatacats = []
    when "landing"
      #Initial load of the homepage
      self.initial = true
      @userdataconts = []
      @userdatabins = []
      @userdatacats = []
    when "nextpage"
      #the next page button has been clicked
      self.keyword_search  = p[:keyword] unless p[:keyword].blank?
      self.page = p[:page]
      duplicateFeatures(old_search)
    when "sortby"
      self.keyword_search  = p[:keyword] unless p[:keyword].blank?
      self.sortby = p[:sortby]
      duplicateFeatures(old_search)
      self.initial = false
    when "filter" 
      createFeatures(p[:filters])
      self.initial = false
    else
      #Error
    end
  end
  
  after_save do
    #Save user filters as well
    (userdataconts+userdatabins+userdatacats).each do |d|
      d.search_id = id
      d.save
    end
  end
 
  # Duplicate the features of search (s) and the last search (os)
  def duplicateFeatures(os)
    @userdataconts = []
    @userdatabins = []
    @userdatacats = []
    if os
      os.userdataconts.each do |d|
        @userdataconts << d.class.new(d.attributes)
      end
      os.userdatacats.each do |d|
        @userdatacats << d.class.new(d.attributes)
      end
      os.userdatabins.each do |d|
        @userdatabins << d.class.new(d.attributes)
      end
      #Save keyword search
      #self.keyword_search = os.keyword_search unless os.keyword_search.blank?
    end
  end
   
  def createFeatures(p)
    #Save keyword search
    self.keyword_search = p[:keyword] unless p[:keyword].blank?
    
    @filters_cats =  []
    @filters_conts = []
    @filters_bins =  []
    
    @userdataconts = []
    @parentconts=[]
    
    unless p[:categorical].nil?
      product_types = p[:categorical][:product_type]
    end  
    current_product_type = Session.product_type
    
    r = /(?<min>[\d.]*);(?<max>[\d.]*)/
    Maybe(p[:continuous]).each_pair do |k,v|
      unless extra_dynamic_facet?(k, product_types, current_product_type)
        v.split("*").each do |cont|
          if res = r.match(cont)
            @userdataconts << Userdatacont.new({:name => k, :min => res[:min], :max => res[:max]})
          end
        end
      end
    end
    
    #Binary Features
    @userdatabins = []
    Maybe(p[:binary]).each_pair do |k,v|
      unless extra_dynamic_facet?(k, product_types, current_product_type)
        #Handle false booleans
        if v != '0'
          @userdatabins << Userdatabin.new({:name => k, :value => v})
        end
      end
    end
    
    #Categorical Features
    #for the category part, the parents and children are separated in order to be able to make the tree and also do a correct search
    @userdatacats = []
    @parentcats=[]
    Maybe(p[:categorical]).each_pair do |k,v|
      unless extra_dynamic_facet?(k, product_types, current_product_type)
        if k == "product_type"
           temp=[]
           v.split("*").each do |cat|
             nested_cats = cat.split("+")
             nested_cats.each do |subcat|
                @parentcats << Userdatacat.new({:name => k , :value => temp.delete(subcat)})  if temp.include?(subcat)
             end
             temp << nested_cats.last if nested_cats.last 
           end
           temp.each do |t|
              @userdatacats << Userdatacat.new({:name => k, :value => t})
           end
           temp=[]
        else   
          v.split("*").each do |cat|
            @userdatacats << Userdatacat.new({:name => k, :value => cat})
          end
        end
      end
    end
    
    @expanded = p[:expanded].try(:keys)
    
    unless(@old_keyword==keyword_search) 
      @filters_cats = @userdatacats
      @filters_conts = @userdataconts
      @filters_bins = @userdatabins
      @userdataconts = []
      @userdatabins = []
      @userdatacats = []
      @parentcats= []
      @parentconts= []
    end

  end
  
  def extra_dynamic_facet?(facet_name, selected_product_types, current_product_type)
    CachingMemcached.cache_lookup("ExtraFacet#{facet_name}Selected#{selected_product_types}Current#{current_product_type}") do
      # condition true iff the facet is a dynamic facet but a matching product category is not also selected in the search
      category_found = false
      unless facet_name == 'product_type'
        # get the dynamic facets if there are any set for the current product type, otherwise do nothing
        dynamic_facets = Maybe(Facet.find_by_name_and_product_type(facet_name, current_product_type)).dynamic_facets
        unless dynamic_facets.nil? or dynamic_facets.empty?
          unless selected_product_types.nil?
            selected_product_types.split('*').each do |p_type|
              category_found = true unless dynamic_facets.where(:category => p_type).empty?
            end
          end
          if category_found == false
            true
          else
            false
          end
        else
          false
        end
      end
      false
    end
  end
  
  # The intent of this function is to see if filtering is being done on a previously filtered set of clusters.
  # The reason for its existence is that filtering across, say, 50% of the total clusters is faster
  # than starting from the beginning every time.
  # Returns 'true' if the filtering is "expanded", ie., if the new filtering needs to examine clusters that weren't in the previous search.
  def expandedFiltering?(old_search)
    #Continuous feature
    olduserdataconts = old_search.userdataconts
    @userdataconts.each do |f|
      old = olduserdataconts.select{|c|c.name == f.name}.first
      if old # If the oldsession max value is not nil then calculate newrange
        oldrange = old.max - old.min
        newrange = f.max - f.min
        if newrange > oldrange
          return true #Continuous
        end
      end
    end
    #Binary Feature
    @userdatabins.each do |f|
      if f.value == false
        #Only works for one item submitted at a time
        @userdatabins.delete(f)
        return true #Binary
      end
    end
    #Categorical Feature
    olduserdatacats = old_search.userdatacats
    if @userdatacats.empty?
      return true unless olduserdatacats.empty?
    else
      @userdatacats.each do |f|
        return true if f.name == "color" #Color is always an expanded filtering
        old = olduserdatacats.select{|c|c.name == f.name}
        unless old.empty?
          newf = @userdatacats.select{|c|c.name == f.name}
          return true if newf.length == 0 && old.length > 0
          return true if old.length > 0 && newf.length > old.length
        end
      end
    end
    if self.keyword_search.blank?
      return true unless old_search.keyword_search.blank?
    end
    false
  end

  private :products_list, :grouping

end

