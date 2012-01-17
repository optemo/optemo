  # -*- coding: utf-8 -*-
require 'sunspot_spellcheck'
require 'will_paginate/array'

class Search < ActiveRecord::Base
  attr_writer :userdataconts, :userdatacats, :userdatabins, :products_size
  attr_accessor :collation, :col_emp_result, :num_result, :has_keysearch
  
  self.per_page = 18 #for will_paginate
  
  def filtering_cat_cont_bin_specs(mybins,mycats,myconts, search_term=nil)
    
    @filtering = Product.search do
   
      if search_term
        phrase = search_term.downcase.gsub(/\s-/,'').to_s
        fulltext phrase
      end  
    
      order_by(:saleprice, :asc) if sortby == "saleprice_factor"
      order_by(:saleprice, :desc) if sortby == "saleprice_factor_high"
      order_by(:orders, :desc) if sortby == "orders"
      order_by(:displayDate, :desc) if sortby == "displayDate"
      
      any_of do  #disjunction inside the category part
        mycats.each do |cats|
          # puts "cats_name #{cats.name} cats_value #{cats.value}"        
          if (cats.name == "category")
            with cats.name.to_sym, cats.value 
          end             
        end   
      end     
      any_of do   # disjunction inside the brand part
        mycats.each do |cats|
          if (cats.name == "brand")
            with cats.name.to_sym, cats.value 
          end             
        end   
      end      
      all_of do  #conjunction for the other cats, bins, and conts specs
         mycats.each do |cats|
            if (cats.name != "category" && cats.name != "brand")
              with cats.name.to_sym, cats.value 
            end     
          end   
         mybins.each do |bins|
          # puts "bins_name #{bins.name} bins_value #{bins.value}"
           with bins.name.to_sym, bins.value
         end      
        myconts.each do |conts|
          # puts "conts_name #{conts.name} conts_value #{conts.value}"
           with (conts.name.to_sym), [conts.min..conts.max]
           
         end  
      end
      
      with :instock, 1
      paginate :page=> page, :per_page => Search.per_page
      group :eq_id_str do 
        ngroups 
      end
      if (!search_term)
        with :product_type, Session.product_type
      end
    end
    
    #puts "group_matches #{@filtering.group(:eq_id_str).matches}"
    #puts "filtering_suggestions: #{@filtering.suggestions}"
    @filtering
  end
  def userdataconts
      @userdataconts ||= Userdatacont.find_all_by_search_id(id)
  end
  
  def userdatacats
      @userdatacats ||= Userdatacat.find_all_by_search_id(id)
  end
  
  def userdatabins
      @userdatabins ||= Userdatabin.find_all_by_search_id(id)
    #  @userdatabins.each do |s|
    #    puts "userdatabins_ #{s.name}"
    #  end
  end
  
  
  #Range of product offerings
  def ranges(featureName)
     @sRange ||= {}
     if @sRange[featureName].nil?
       min = clusters.map{|c|c.ranges(featureName)[0]}.compact.sort[0]
       max = clusters.map{|c|c.ranges(featureName)[1]}.compact.sort[-1] 
       @sRange[featureName] = [min, max]
     end
     @sRange[featureName]  
  end
  
  def indicator(featureName)
    indic = false
    values = clusters.map{|c| c.indicator(featureName)}
    if values.index(false).nil?
      indic = true
    end  
    indic
  end
    
  def minimum(feature)
    feature = feature + "_min"
    min = clusters[0].send(feature)
    for i in 1..cluster_count-1
      min = clusters[i].send(feature) if clusters[i].send(feature) < min
    end
    min
  end
  
  def maximum(feature)
    feature = feature + "_max"
    max = clusters[0].send(feature)
    for i in 1..cluster_count-1
      max = clusters[i].send(feature) if clusters[i].send(feature) > max
    end
    max
  end
  
  #The clusters argument can either be an array of cluster ids or an array of cluster objects if they have already been initialized
  def cluster
    @cluster ||= Cluster.new(sim_products, nil)
  end
 
  def paginated_products #set the paginated_products
    unless @paginated_products
       products
    end
    @paginated_products
  end

  def isextended?
    !@extended.nil?
  end  
  
  def extend_it(extended_obj=nil)
    @extended = extended_obj unless extended_obj.nil?
  end  
  def extended
      @extended ||= Cluster.new(products)
  end
 
  def products_size
     unless @products_size
       products
      end
      @products_size
        
  end  
    
  def products
   mycats = self.userdatacats
   mybins = self.userdatabins
   myconts = self.userdataconts
   emp_specs = mybins.empty? && mycats.empty? && myconts.empty?
   @has_keysearch = false 
  
    if (keyword_search && !emp_specs)
       @has_keysearch = true
      things = filtering_cat_cont_bin_specs(mybins,mycats,myconts, keyword_search)
      res = grouping(things)
      @num_result = things.group(:eq_id_str).ngroups
      
      if (res.empty? && things.collation != nil)
        @collation = things.collation
        things_col= filtering_cat_cont_bin_specs(mybins,mycats,myconts, @collation)
        res_col = grouping(things_col)
        if (res_col.empty?)
          @col_emp_result = true
        end
         products_list(res_col,things_col.group(:eq_id_str).ngroups)
         #@products = res_col
      
      else
        products_list(res,things.group(:eq_id_str).ngroups)
        # @products = res
  
      end
    elsif (keyword_search)
       @has_keysearch = true
      @keysearch = product_keywordsearch(keyword_search)
      @num_result = @keysearch.total
      
      #puts "phrase-jan10-search #{phrase}"
      #puts "suggestions, #{@keysearch.suggestions}"
      #puts "keysearch_total #{@keysearch.total}"
      #puts "total_pages_results: #{@keysearch.results.total_pages}"
      
       if (@keysearch.suggestions!=nil && !@keysearch.suggestions.empty?)
         @collation = @keysearch.collation
         @sug_products = product_keywordsearch(@collation)
         
         if (@sug_products.results.empty?)
           @col_emp_result = true;
         end
         if (@keysearch.results.empty? && !@col_emp_result)
           products_list(@sug_products.results,@sug_products.total )
          # @products = @sug_products.results
           
         else
            products_list(@keysearch.results, @keysearch.total)
           # @products  = @keysearch.results
         end
       else
          products_list(@keysearch.results, @keysearch.total)
         # @products  = @keysearch.results
       end             
    elsif (emp_specs)
     things= filtering_cat_cont_bin_specs([],[],[])
     products_list(grouping(things), things.group(:eq_id_str).ngroups)
    
     
    else
      things = filtering_cat_cont_bin_specs(mybins,mycats,myconts)
      products_list( grouping(things), things.group(:eq_id_str).ngroups)
      
     
    end
  end
    
  def product_keywordsearch (phrase = self.keyword_search)
      phrase = phrase.downcase.gsub(/\s-/,'').to_s    

      products_found = Product.search 
       products_found.build do  
        fulltext phrase
        with :instock, 1
        spellcheck :count => 4
        
        order_by(:saleprice, :asc) if sortby == "saleprice_factor"
        order_by(:saleprice, :desc) if sortby == "saleprice_factor_high"
        order_by(:orders, :desc) if sortby == "orders"
        order_by(:displayDate, :desc) if sortby == "displayDate"
      
        paginate :page=> page, :per_page => Search.per_page
       end
        products_found.execute!
     products_found
  end
  
  def grouping(things)    
    res=[]
    things.group(:eq_id_str).groups.each do |g|
         res << g.results.first
    end
    res
  end
  
  def products_list(things, total) #paginate products through sunspot pagination
     @products_size = total    
     @paginated_products = Sunspot::Search::PaginatedCollection.new things, page||1, Search.per_page,total
   end
   
  def products_landing
    @landing_products ||= CachingMemcached.cache_lookup("FeaturedProducts(#{Session.product_type}") do
      BinSpec.find_all_by_name_and_product_type("featured",Session.product_type)
    end
  end
=begin  
  def sim_products
    if seesim
      begin
        @simproducts ||= products & Cluster.cached(seesim)
      rescue IOError
        #In case the similar products can't be found, just load the filtered products instead of throwing an error
        products
      end
    else
      products
    end
  end
 
  def sim_products_size
    @sim_products_size ||= sim_products.size
  end

  def groupings
    return [] if groupby.nil? 
    if Session.currrent.features["filter"].select{|f|f.feature_type == "Categorical"}.index(groupby) 
      # It's in the categorical array
      specs = products.zip CatSpec.cachemany(products, groupby)
      grouping = specs.group_by{|spec|spec[1]}.values.sort{|a,b| b.length <=> a.length}
    elsif Session.currrent.features["filter"].select{|f|f.feature_type == "Continuous"}.index(groupby) 
      #The chosen feature is continuous
      specs = products.zip ContSpec.by_feat(groupby).sort
      # [[id, low], [id, higher], ... [id, highest]]
      quartile_length = (specs.length / 4.0).ceil
      quartiles = []
      3.times do
        quartiles << specs.slice!(0,[quartile_length,specs.length].min)
      end
      quartiles << specs #The last quartile contains any extra products
      
      #Break boundry cases in quartiles where the same item is in two quartiles according to the following pattern
      # 1 ↓
      # 2
      # 3 ↑
      # 4 ↑

      #Move ties from Q1 to Q2
      unless quartiles[0].blank? || quartiles[1].blank?
        threshold_value = quartiles[1].first[1]
        splitpoint = quartiles[0].index(quartiles[0].find {|spec| spec[1] == threshold_value})
        quartiles[1] = quartiles[0].slice!(splitpoint..-1) + quartiles[1] unless splitpoint.nil?
      end
      
      #Move ties from Q4 to Q3
      unless quartiles[2].blank? || quartiles[3].blank?
        threshold_value = quartiles[2].last[1]
        splitpoint = quartiles[3].index(quartiles[3].reverse.find {|spec| spec[1] == threshold_value})
        quartiles[2] = quartiles[2] + quartiles[3].slice!(0..splitpoint) unless splitpoint.nil?
      end
      
      #Move ties from Q3 to Q2
      unless quartiles[1].blank? || quartiles[2].blank?
        threshold_value = quartiles[1].last[1]
        splitpoint = quartiles[2].index(quartiles[2].reverse.find {|spec| spec[1] == threshold_value})
        quartiles[1] = quartiles[1] + quartiles[2].slice!(0..splitpoint) unless splitpoint.nil?
      end
      
      grouping = quartiles.reject(&:blank?) # For cases like 9 items, where the quartile length ends up being 3.

    else # Binary feature. Do nothing for now.
    end
    grouping.map do |q|
      product_ids = q.map(&:first)
      prices_list = ContSpec.cachemany(product_ids,"saleprice")
      utility_list = ContSpec.cachemany(product_ids, "utility")
      {
        :min => q.first.last.to_s,
        :max => q.last.last.to_s,
        :size => q.count,
        :cheapest =>  Product.cached(product_ids[prices_list.index(prices_list.max)]),
        :best => Product.cached(product_ids[utility_list.index(utility_list.max)])
      }
    end
  end
=end  
  def initialize(p={}, opt=nil)
    super({})
    #Set parent id
    self.parent_id = CGI.unescape(p[:parent]).unpack("m")[0].to_i unless p[:parent].blank?
    unless p[:action_type] == "allproducts" || p[:action_type] == "landing" #Exception for initial clusters
      old_search = Search.find_by_id(self.parent_id)
    end
    # If there is a sort method to keep from last time, move it across
    self.sortby = old_search[:sortby] if old_search && old_search[:sortby]
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
    when "similar"
      #Browse similar button
      self.seesim = p["cluster_hash"] # current products
      duplicateFeatures(old_search)
    when "extended"
      self.seesim = p["extended_hash"] # current products
      createFeatures(p)
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
    when "groupby"
      self.groupby = p[:feat]
      duplicateFeatures(old_search)
    when "filter"
      #product filtering has been done through keyword search of attribute filters
      puts "filter_params: #{p[:filters]}"
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
    @userdataconts = []
    r = /(?<min>[\d.]*)-(?<max>[\d.]*)/
    Maybe(p[:continuous]).each_pair do |k,v|
      #Split range into min and max
      if res = r.match(v)
        @userdataconts << Userdatacont.new({:name => k, :min => res[:min], :max => res[:max]})
      end
    end
    
    #Binary Features
    @userdatabins = []
    Maybe(p[:binary]).each_pair do |k,v|
      #Handle false booleans
      if v != '0'
        @userdatabins << Userdatabin.new({:name => k, :value => v})
      end
    end
    
    #Categorical Features
    @userdatacats = []
    Maybe(p[:categorical]).each_pair do |k,v|
      v.split("*").each do |cat|
        @userdatacats << Userdatacat.new({:name => k, :value => cat})
      end
    end
    
    cats = []
    #Check for cat filters which have been eliminated by other filters
    @userdatacats.group_by(&:name).each_pair do |k,v|
      # get all categories
      if k=='category'
        v.each { |x| cats << x.value }
      end
      if v.size > 1
        counts = CatSpec.count_feat(k,false,self)
        v.each do |val|
          @userdatacats.reject!{|c|c.name == k && c.value == val.value} if counts[val.value].nil? || counts[val.value] == 0
        end
      end
    end
    
    #Save keyword search
    self.keyword_search = p[:keyword] unless p[:keyword].blank?
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
  private :products_list, :grouping, :product_keywordsearch, :filtering_cat_cont_bin_specs
end
