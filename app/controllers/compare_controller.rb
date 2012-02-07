class CompareController < ApplicationController
  layout :choose_layout, :except => "sitemap"
  require 'open-uri'
  def index
    # For more information on _escaped_fragment_, google "google ajax crawling" and check lib/absolute_url_enabler.rb.
    if Session.isCrawler?(request.user_agent, params[:_escaped_fragment_]) || params[:ajax] || params[:embedding]
      if (params[:page] && params[:keyword] && params[:keyword] != "Keyword or Web Code" )
        classVariables(Search.create({page: params[:page], keyword: params[:keyword], sortby: params[:sortby] || 'utility', action_type: "nextpage", parent: params[:hist]}))
      
      elsif params[:page]
           classVariables(Search.create({page: params[:page], sortby: params[:sortby] || 'utility', action_type: "nextpage", parent: params[:hist]}))  
      
      elsif (params[:sortby] && params[:keyword] && params[:keyword] != "Keyword or Web Code") # Change sorting method via navigator_bar select box
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
    else
      @indexload = true
    end
    correct_render
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
 
  # Depending on the session, either use the traditional layout or the "optemo" layout.
  # The CSS files are loaded automatically though, so the usual "sv / gv / lv / mv" CSS classes are needed.
  def choose_layout
    if params[:embedding]
      'embedding'
    else
      'optemo'
    end
  end
  
  def classVariables(search)
    @s = Session
    @s.search = search
    @s.set_features(search.userdatacats.select{|d| d.name == 'category'}.map{|d| d.value})
  end
  
  def correct_render
    if params[:ajax]
      if Session.search.initial
        render 'ajax_landing', :layout => false
      elsif (params[:keyword] || !Session.search.keyword_search.blank?)
        render 'ajax_search', :layout => false
      else      
        render 'ajax', :layout => false
       # end      
      end
    else
      render 'compare'
    end
  end
end
