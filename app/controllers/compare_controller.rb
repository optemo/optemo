class CompareController < ApplicationController
  layout :choose_layout, :except => "sitemap"
  require 'open-uri'
  
  def index
    # For more information on _escaped_fragment_, google "google ajax crawling" and check lib/absolute_url_enabler.rb.
    if Session.isCrawler?(request.user_agent, params[:_escaped_fragment_]) || params[:ajax] || params[:embedding]
      hist = params[:hist].gsub(/\D/,'').to_i if params[:hist]
      search_history = Session.current.searches if hist && params[:page].nil?
      if params[:page]
        classVariables(Search.create({:page => params[:page], "action_type" => "nextpage"}))
      elsif search_history && hist <= search_history.length && hist > 0
        #Going back to a previous search
        classVariables(search_history[hist-1])
      else
        #Initial clusters
        classVariables(Search.create({"action_type" => "initial"}))
      end
    else
      @indexload = true
    end
    correct_render
  end 
  
  def bot
    classVariables(Search.create({"action_type" => "initial"}))
    render 'compare'
  end

  def groupby
    # Group products by specified feature
    classVariables(Search.create(:feat => params[:feat], "action_type" => "groupby"))
    correct_render
  end
  
  #For mobile layout
  def filtering
    #Choose filter options
    classVariables(Session.current.searches.last)
    render 'mobile-filters', :layout=>'filters'
  end
  
  def sim
    # Explore products through clusters
    classVariables(Search.create({"cluster_hash" => params[:id], "action_type" => "similar"}))
    correct_render
  end

  def create
    #Narrow the product search through filters
    if params[:myfilter].nil?
      #No post info passed
      render :text =>  "[ERR]Search could not be completed."
    else
      # We need to propagate the previous search term if the new search term is blank (this should be done is JS)
      if (!params[:previous_search_word].blank? && params[:myfilter][:search].blank?)
        params[:myfilter][:search] = params[:previous_search_word]
      end
      #The search should only be able to fail from bad keywords, as empty searches can't be selected
      if !params[:myfilter][:search].blank? && !Search.keyword(params[:myfilter][:search])
        #Rollback
        classVariables(Session.current.lastsearch)
        @errortype = "filter"
        if Session.current.mobileView
          render 'error'
        else 
          render 'error', :layout => false
        end
      else
        params[:myfilter]["action_type"] = "filter"
        classVariables(Search.create(params[:myfilter]))
        correct_render
      end
    end
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @plain = params[:plain].nil? ? false : true
    
    #Cleanse id to be only numbers
    params[:id] = params[:id][/^\d+/]
    @product = Product.cached(params[:id])
    @allspecs = ContSpec.cache_all(params[:id]).merge(CatSpec.cache_all(params[:id])).merge(BinSpec.cache_all(params[:id]))
    @s = Session.current
    product_type = @s.product_type
    if product_type
      if product_type == "flooring_builddirect"
        @imglurl = "http://www.builddirect.com" + CGI.unescapeHTML(@product.imglurl.to_s)
      elsif product_type == "Laptop"
        @imglurl = @product.imgurl.to_s
      else
        @imglurl = @product.imglurl
      end
    else
      @imglurl = @product.imglurl
    end

    @offerings = RetailerOffering.find_all_by_product_id_and_product_type(params[:id], product_type, :order => 'priceint ASC')
    @review = Review.find_by_product_id_and_product_type(params[:id], product_type, :order => 'helpfulvotes DESC')
    # Take out offending <br />
    if @review && @review.content
      @review.content = @review.content.gsub(/\r\&lt\;br \/\&gt\;/, '').gsub(/\t/,' ').strip
    end
    @cartridges = Compatibility.find_all_by_product_id_and_product_type(@product.id, product_type).map{|c|Cartridge.find_by_id(c.accessory_id)}.reject{|c|!c.instock}
    @cartridgeprices = @cartridges.map{|c| RetailerOffering.find_by_product_type_and_product_id("Cartridge",c.id)}
    respond_to do |format|
      format.html { 
                    if @plain 
                      render :layout => false
                    elsif Session.current.mobileView
                      render 'showsimple'
                    else # Default is with layout as particular to either mobile view or screen view in choose_layout
                      render 'show' # What did "render :http => ..." used to do? confusion
                    end }
      format.xml  { render :xml => @product }
    end
  end
  
  private
  # Depending on the session, either use the traditional layout or the "optemo" layout.
  # The CSS files are loaded automatically though, so the usual "sv / gv / lv / mv" CSS classes are needed.
  def choose_layout
    if params[:embedding]
      'embedding'
    else
      Session.current.mobileView ? 'mobile' : 'optemo'
    end
  end
  
  def classVariables(search)
    @s = Session.current
    @s.search = search
    if @s.directLayout
      @products = search.products.paginate :page => search.page, :per_page => 10
    end
  end
  
  def correct_render
    if params[:ajax]
      render 'ajax', :layout => false
    else
      if Session.current.mobileView
        classVariables(Search.create({"page" => params[:page], "action_type" => "initial"}))
        render 'products'
      else
        render 'compare'
      end
    end
  end
end
