# -*- coding: utf-8 -*-
require 'sunspot_spellcheck'
require 'will_paginate/array'

class Search < ActiveRecord::Base
  attr_writer :userdataconts, :userdatacats, :userdatabins, :products_size, :keyword
  attr :suggestions, :collation, :sc_emp_result, :keyword
  
  def userdataconts
      @userdataconts ||= Userdatacont.find_all_by_search_id(id)
  end
  
  def userdatacats
      @userdatacats ||= Userdatacat.find_all_by_search_id(id)
  end
  
  def userdatabins
      @userdatabins ||= Userdatabin.find_all_by_search_id(id)
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
  
  def paginated_products
    unless @paginated_products
      #if sortby == "utility" || sortby.nil?
      #  myproducts = Kmeans.compute(18,products.dup)
      #else
      #  myproducts = products
      #end
      @paginated_products = products.paginate(:page => page, :per_page => SearchProduct.per_page)
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
    @products_size ||= products.size
  end
  
  def products
    if @keyword
      phrase = @keyword
      @sc_emp_result = false
     @keysearch ||= Product.search do
        fulltext phrase
        spellcheck :count => 5
        with :instock, 1
        
        #with(:published_at).less_than Time.now
        #order_by :published_at, :desc
        #paginate :page => 2, :per_page => 15
        #facet :category_ids, :author_id
     end
     if (!@keysearch.suggestions.empty?)
          puts "suggestions: #{@keysearch.suggestions}"
          @suggestions = @keysearch.suggestions
          @collation = @keysearch.collation
         
         if (@keysearch.results.empty?)
                @sc_emp_result = true 
                phrase = @keysearch.collation        
                @products ||= Product.search do
                         fulltext phrase
                         with :instock, 1
                  end.results   
                
         else
             @products =@keysearch.results
         end
               
     else    
        @products =@keysearch.results                          
     end
   else
      @products ||= ContSpec.fq2
    end
  end
  
  def products_landing
    @landing_products ||= CachingMemcached.cache_lookup("FeaturedProducts(#{Session.product_type}") do
      BinSpec.find_all_by_name_and_product_type("featured",Session.product_type)
    end
  end
  
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
      self.page = p[:page]
      duplicateFeatures(old_search)
    when "sortby"
      self.sortby = p[:sortby]
      duplicateFeatures(old_search)
      self.initial = false
    when "groupby"
      self.groupby = p[:feat]
      duplicateFeatures(old_search)
    when "filter"
      #product filtering has been done through keyword search of attribute filters
      @keyword = p[:keyword]
      @collation = nil
      @suggestions={}
      @sc_emp_result=false
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
end
