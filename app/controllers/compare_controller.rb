class CompareController < ApplicationController
  layout "optemo"
  require 'open-uri'
  require 'iconv'
  
  def index
    unless Session.isCrawler?(request.user_agent) || params[:ajax]
      @indexload = true
    end
    # The page numbers have to go in for pagination
    page_number = {} # This has to be a hash for compatibility with Search.createSearchAndCommit()
    page_number["page"] = params[:page]
    current_search = Search.createInitialClusters(page_number)
    classVariables(current_search)
    if params[:ajax]
      render 'ajax', :layout => false
    else
      render 'compare'
    end
  end
  
  def groupby
    feat = params[:feat]
    # We need to make a new search so that history works properly (back button can take to "groupby" view)
    old_search = Session.current.searches.last
    current_search = old_search.clone # copy over session ID, etc.
    current_search.view = feat # save feature for later. Any feature in "view" means we're in groupby view
    current_search.save
    Session.current.search = current_search
    Search.duplicateFeatures(current_search, old_search) # copy over filters
    @groupings = Search.createGroupBy(feat)
    @groupedfeature = feat
    render 'ajax', :layout => false
  end
  
  def compare(hist = nil)
    # As of right now, the history function from javascript always points here.
    # What will need to happen is that the view will be in there as part of the search. I think.
    hist = params[:hist].gsub(/\D/,'').to_i if params[:hist]
    #Going back to a previous search
    if hist
      search_history = Session.current.searches
      if hist <= search_history.length && hist > 0
        mysearch = search_history[hist-1]
        mysearch.page = params[:page] if params[:page] # For this case: back button followed by clicking a pagination link
        classVariables(mysearch)
        if mysearch.view
          @groupings = Search.createGroupBy(mysearch.view)
          @groupedfeature = mysearch.view
        end        
      else
        page_number = {} # This has to be a hash for compatibility with Search.createSearchAndCommit()
        page_number["page"] = params[:page]
        current_search = Search.createInitialClusters(page_number)
        classVariables(current_search)
      end
    else
      # No need to send in the previous search term since it will be copied automatically. Same with filters.
      # The exception is the 'page' parameter, which might be modified and need writing.
      # Since the myfilter hash is always empty, we just send a hash with only the page number, if any.
      classVariables(Search.createSearchAndCommit(Session.current.searches.last), params[:id].split('-'), { "page" => params[:page] }) 
    end
    render 'ajax', :layout => false
  end
  
  def classVariables(search)
    @s = Session.current
    @s.search = search
    if @s.directLayout
      page = search.page
      @products = search.products.paginate :page => page, :per_page => 10
    end
  end
  
  def sim
    cluster_id = params[:id]
    cluster_id.gsub(/[^(\d|+)]/,'') #Clean URL input
    Session.current.search = Session.current.searches.last
    if cluster_id.index('+')
      #Merged Cluster
      cluster = MergedCluster.fromIDs(cluster_id.split('+'))
    else
      #Single, normal Cluster
      cluster = Cluster.cached(cluster_id)
    end
    unless cluster.nil?
      if params[:ajax]
        current_search = Search.createSearchAndCommit(Session.current.searches.last, cluster.children)
        classVariables(current_search)
        render 'ajax', :layout => false
      else
        redirect_to "/compare/compare/"+cluster.children.map{|c|c.id}.join('-')
      end
    else
      redirect_to "/compare/compare/"
    end
  end

  def filter
    s = Session.current
    if params[:myfilter].nil? && params[:search].nil? && params[:page].nil?
      #No post info passed
      render :text =>  "[ERR]Search could not be completed."
    else
      # We need to propagate the previous search term if the new search term is blank
      if (!params[:previous_search_word].blank? && params[:search].blank?)
         current_search_term = params[:previous_search_word]
      else
        current_search_term = params[:search]
      end
      old_search = s.searches.last
      s.search = old_search
      # Put the 'page' parameter in paginated output into the :myfilter hash for ease in processing
      params[:myfilter] = {} unless params[:myfilter] # the hash will be empty on page number clicks
      params[:myfilter]["page"] = params[:page]
      current_search = Search.createSearchAndCommit(old_search, nil, params[:myfilter], current_search_term)
      unless (s.directLayout ? current_search.products.empty? : current_search.clusters.empty?)
        classVariables(current_search)
        render 'ajax', :layout => false
      else
        #Rollback
        s.search = old_search
        @errortype = "filter"
        render 'error', :layout=>true
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
      format.html { if @plain
                      render :layout => false
                    else
                      render :http => 'show' , :layout => 'optemo'
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

end
