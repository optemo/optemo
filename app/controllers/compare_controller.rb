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
  
  #This function should be combined with create
  def featured
      classVariables(Search.create(:action_type => "featured", :parent => params[:hist]))
      correct_render
  end     
    
  def groupby
    # Group products by specified feature
    classVariables(Search.create(:feat => params[:feat], :action_type => "groupby"))
    correct_render
  end
  
  #For mobile layout
  def filtering
    #Choose filter options
    classVariables(Session.searches.last)
    render 'mobile-filters', :layout=>'filters'
  end
  
  #This function should be combined with create
  def sim
    # Explore products through clusters
    classVariables(Search.create({"cluster_hash" => params[:id], :action_type => "similar", :parent => params[:hist]}))
    correct_render
  end
   
  def extended
    params[:action_type]= "extended"
    classVariables(Search.create(params))
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

  # GET /products/1
  # GET /products/1.xml
  def show
    if Session.product_type == "camera_bestbuy" && Session.isCrawler?(request.user_agent,nil)
      redirect_to '/compare#index'
    else
      @plain = params[:plain].nil? ? false : true
      
      #Cleanse id to be only numbers
      id = params[:id] = params[:id][/^\d+/]
      @product = Product.cached(id)
      @prod_url = TextSpec.cacheone(@product.id, "productUrl#{fr?}")
      @allspecs = ContSpec.cache_all(id).merge(CatSpec.cache_all(id)).merge(BinSpec.cache_all(id)).merge(TextSpec.cache_all(id))
      @siblings = ProductSibling.find_all_by_product_id_and_name(id,"imgsurl")
      @s = Session
      
      respond_to do |format|
        format.html { 
                      if @plain 
                        render :layout => false
                      else # Default is with layout as particular to either mobile view or screen view in choose_layout
                        render 'show' # What did "render :http => ..." used to do? confusion
                      end }
        format.xml  { render :xml => @product }
      end
    end
  end
 
  # Depending on the session, either use the traditional layout or the "optemo" layout.
  # The CSS files are loaded automatically though, so the usual "sv / gv / lv / mv" CSS classes are needed.
  def choose_layout
    if params[:embedding]
      'embedding'
    else
      Session.mobileView ? 'mobile' : 'optemo'
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
