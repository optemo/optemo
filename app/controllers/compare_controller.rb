class CompareController < ApplicationController
  layout 'optemo', :except => "sitemap"
  require 'open-uri'
  def index
    # For more information on _escaped_fragment_, google "google ajax crawling" and check lib/absolute_url_enabler.rb.

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
  
  def classVariables(search)
    Session.search = search
    @search_view = true if params[:keyword] || !Session.search.keyword_search.blank?
    selected_product_type = search.userdatacats.select{|d| d.name == 'product_type'}.map{|d| d.value}
    selected_product_type = effective_product_type(search) if selected_product_type.empty?
    Session.initialize_product_type(selected_product_type.first)
    Session.set_features(selected_product_type)
  end
  
  def effective_product_type(search)
    current_product_type = Session.product_type
    counts = count_current_spec("product_type")
    if counts.keys.length == 1
      [counts.keys.first]
    else
      ProductCategory.get_ancestors(counts.keys)
    end
  end
  
  def count_current_spec(feat)
    Session.search.solr_products_count.facet(feat.to_sym).rows.inject({}) do |q,r|
      q[r.value] = r.count
      q
    end
  end
  
  def correct_render
    if params[:ajax] || params[:embedding]
      render 'ajax', :layout => false
    else
      render 'compare'
    end
  end
end
