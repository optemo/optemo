class CompareController < ApplicationController
  layout 'optemo', :except => "sitemap"
  require 'open-uri'
  def index
    # For more information on _escaped_fragment_, google "google ajax crawling" and check lib/absolute_url_enabler.rb.

    if (params[:page] && params[:keyword] && params[:keyword] != "Search terms" )
      classVariables(Search.create({page: params[:page], keyword: params[:keyword], sortby: params[:sortby] || 'utility', action_type: "nextpage", parent: params[:hist]}))
    
    elsif params[:page]
         classVariables(Search.create({page: params[:page], sortby: params[:sortby] || 'utility', action_type: "nextpage", parent: params[:hist]}))  
    
    elsif (params[:sortby] && params[:keyword] && params[:keyword] != "Search terms") # Change sorting method via navigator_bar select box
      classVariables(Search.create({sortby: params[:sortby], keyword: params[:keyword], action_type: "sortby", parent: params[:hist]}))
    
    elsif params[:sortby]
       classVariables(Search.create({sortby: params[:sortby], action_type: "sortby", parent: params[:hist]}))  
    
    else
      hist = CGI.unescape(params[:hist]).unpack('m')[0].gsub(/\D/,'').to_i if params[:landing].nil? && params[:hist] && !params[:hist].blank?
      search_history = Search.find_last_by_parent_id(hist) if hist
      if search_history
        #Going back to a previous search
        classVariables(search_history)
      else
        #Initial clusters
        classVariables(Search.create({:action_type => params[:landing].nil? ? "allproducts" : "landing", :parent => params[:hist]}))
      end
    end
    correct_render
    #Don't use private cache so that varnish can cache
    #expires_in(5.minutes, public: true) if params[:hist].blank?
  end

  def create
    if (params[:keyword] && params[:keyword] =~ /[0-9BM]\d{7}/ && Product.find_by_sku(params[:keyword])!=nil )
      # Redirect directly to the PDP
       render text: "[REDIRECT]#{ TextSpec.cacheone((Product.find_by_sku(params[:keyword])).id, "productUrl")}"
    else
      classVariables(Search.create(action_type: "filter", parent: params[:hist], filters: params))
      correct_render
    end
  end
  
  def classVariables(search)
    Session.search = search
    @search_view = true if params[:keyword] || !Session.search.keyword_search.blank?
    Session.set_features(search.userdatacats.select{|d| d.name == 'product_type'}.map{|d| d.value})
    @t = Translation.cache_product_translations
  end
  
  def correct_render
    if params[:ajax] || params[:embedding]
      render 'ajax', :layout => false
    else
      render 'compare'
    end
  end
end
