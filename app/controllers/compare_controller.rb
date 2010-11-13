class CompareController < ApplicationController
  layout :choose_layout
  require 'open-uri'
  
  def index
    if Session.isCrawler?(request.user_agent) || params[:ajax]
      hist = params[:hist].gsub(/\D/,'').to_i if params[:hist]
      search_history = Session.current.searches if hist
      if search_history && hist <= search_history.length && hist > 0
        #Going back to a previous search
        mysearch = search_history[hist-1]
        mysearch.page = params[:page] if params[:page] # For this case: back button followed by clicking a pagination link
        classVariables(mysearch)
      else
        #Initial clusters
        classVariables(Search.create({"page" => params[:page], "action_type" => "initial"})) ### why initial??
      end
    else
      @indexload = true
    end

    if params[:ajax]
      render 'ajax', :layout => false
    else
      render (Session.current.mobileView ? 'products' : 'compare')
    end
  end

  def groupby
    # We need to make a new search so that history works properly (back button can take to "groupby" view)
    classVariables(Search.create(:feat => params[:feat], "action_type" => "groupby"))
    render 'ajax', :layout => false
  end
  
  #For mobile layout
  def showfilters
    classVariables(Session.current.searches.last)
    render 'filters', :layout=>'filters'
  end
  
  def classVariables(search)
    @s = Session.current
    @s.search = search
    if @s.directLayout
      @products = search.products.paginate :page => search.page, :per_page => 10
    end
  end
  
  def sim
    classVariables(Search.create({"cluster_hash" => params[:id].gsub(/[^(\d)]/,''), "action_type" => "similar"}))
    if params[:ajax]
      render 'ajax', :layout => false
    else
      render (Session.current.mobileView ? 'products' : 'compare')
    end
  end

  def filter
    if params[:myfilter].nil? && params[:page].nil?
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
        render 'error', :layout=>true
      else
        params[:myfilter] = {} unless params[:myfilter] # the hash will be empty on page number clicks
        params[:myfilter]["page"] = params[:page]
        params[:myfilter]["action_type"] = "filter"
        classVariables(Search.create(params[:myfilter]))
        if Session.current.mobileView
          render 'products' 
        else 
          render 'ajax', :layout => false
        end
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

  def searchterms
#    # There is a strange beauty in the illegibility of the following line.
#    # Must do a join followed by a split since the initial mapping of titles is like this: ["keywords are here", "and also here", ...]
#    # The gsub lines are to take out the parentheses on both sides, take out commas, and take out trailing slashes.
#    searchterms = findCachedTitles.join(" ").split(" ").map{|t| t.tr("()", '').gsub(/,/,' ').gsub(/\/$/,'').chomp}.uniq
#    # Delete all the 1200x1200dpi, the "/" or "&" strings, all two-letter strings, and things that don't start with a letter or number.
#    searchterms.delete_if {|t| t == '' || t.match('[0-9]+.[0-9]+') || t.match('^..?$') || t.match('^[^A-Za-z0-9]') || t.downcase.match('^print')}
##    duplicates = searchterms.inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys
#    @searchterms = searchterms.map{|t|t.match(/[^A-Za-z0-9]$/)? t.chop.downcase : t.downcase }.uniq.join('[BRK]')
#    # Particular to this data
#    render 'searchterms', :layout => false
  render :text => "word"
  end

  private
  # Depending on the session, either use the traditional layout or the "optemo" layout.
  # The CSS files are loaded automatically though, so the usual "sv / gv / lv / mv" CSS classes are needed.
  def choose_layout 
    Session.current.mobileView ? 'mobile' : 'optemo'
  end
end
