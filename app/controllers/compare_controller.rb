class CompareController < ApplicationController
  layout :choose_layout, :except => "sitemap"
  require 'open-uri'
  
  def index
    if params.include?(:fb_xd_fragment)
      render 'customFacebookChannel', :layout => false
      # A custom channel is required to avoid ?fb_xd_fragment calls (which load index.html and have side effects) in MSIE 7-9
    else
      # For more information on _escaped_fragment_, google "google ajax crawling" and check lib/absolute_url_enabler.rb.
      if Session.isCrawler?(request.user_agent, params[:_escaped_fragment_]) || params[:ajax] || params[:embedding]
        hist = Base64.decode64(params[:hist]).gsub(/\D/,'').to_i if params[:hist] && !params[:hist].blank?
        search_history = Search.find_by_parent_id(hist) if hist && params[:page].nil?
        if params[:page]
          classVariables(Search.create({:page => params[:page], :sortby => params[:sortby], "action_type" => "nextpage"}))
        elsif search_history
          #Going back to a previous search
          classVariables(search_history)
        elsif params[:sortby] # Change sorting method via navigator_bar select box
          classVariables(Search.create({:sortby => params[:sortby], "action_type" => "sortby"}))
        else
          #Initial clusters
          classVariables(Search.create({:sortby => params[:sortby], "action_type" => "initial"}))
        end
      else
        @indexload = true
      end
      correct_render
    end
  end
  
  def zoomout
    # Zoom out of see similar
    classVariables(Search.create("action_type" => "nextpage"))
    correct_render
  end

  def groupby
    # Group products by specified feature
    classVariables(Search.create(:feat => params[:feat], "action_type" => "groupby"))
    correct_render
  end
  
  #For mobile layout
  def filtering
    #Choose filter options
    classVariables(Session.searches.last)
    render 'mobile-filters', :layout=>'filters'
  end
  
  def sim
    # Explore products through clusters
    classVariables(Search.create({"cluster_hash" => params[:id], "action_type" => "similar"}))
    correct_render
  end

  def extended
    params["action_type"]= "extended"
    classVariables(Search.create(params))
    correct_render 
  end  
  
  def create
    #Narrow the product search through filters
    params[:myfilter] = {} if params[:myfilter].nil?
      # We need to propagate the previous search term if the new search term is blank (this should be done is JS)
    if (!params[:previous_search_word].blank? && params[:myfilter][:search].blank?)
      params[:myfilter][:search] = params[:previous_search_word]
    end
    #The search should only be able to fail from bad keywords, as empty searches can't be selected
    if !params[:myfilter][:search].blank? && !Search.keyword(params[:myfilter][:search])
      #Rollback
      classVariables(Session.lastsearch)
      @errortype = "filter"
      if Session.mobileView
        render 'error'
      else 
        render 'error', :layout => false
      end
    else
      params[:myfilter]["action_type"] = "filter"
      params[:myfilter]["parent"] = params[:hist] if params[:hist]
      classVariables(Search.create(params[:myfilter]))
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
      @siblings = ProductSiblings.find_all_by_product_id_and_name(id,"imgsurl")
      @s = Session
      
      respond_to do |format|
        format.html { 
                      if @plain 
                        render :layout => false
                      elsif Session.mobileView
                        render 'showsimple'
                      else # Default is with layout as particular to either mobile view or screen view in choose_layout
                        render 'show' # What did "render :http => ..." used to do? confusion
                      end }
        format.xml  { render :xml => @product }
      end
    end
  end
  
  private
  def fr?
    I18n.locale == :fr ? "_fr" : ""
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
    @jsonp_version = true if request.subdomains.first == "embed"
    @s.search = search
    if @s.directLayout
      @products = search.products.paginate :page => search.page, :per_page => 10
    end
  end
  
  def correct_render
    if params[:ajax]
      render 'ajax', :layout => false
    else
      if Session.mobileView
        classVariables(Search.create({"page" => params[:page], "action_type" => "initial"}))
        render 'products'
      else
        render 'compare'
      end
    end
  end
end
