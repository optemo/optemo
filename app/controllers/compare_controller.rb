class CompareController < ApplicationController
  layout "optemo"
  require 'open-uri'
  require 'iconv'
  
  def index
    if Session.isCrawler?(request.user_agent) || params[:ajax]
      s = Search.createInitialClusters
      classVariables(s)
    else
      @indexload = true
    end
    if params[:ajax]
      render 'ajax', :layout => false
    else
      render 'compare'
    end
  end
  
  def groupby
    feat = params[:feat]
    Session.current.search = Session.current.searches.last
    @groupings = Search.createGroupBy(feat)
    @groupedfeature = feat
    classVariables(Session.current.search)
    render 'ajax', :layout => false
  end
  
  def compare(hist = nil)
    hist = params[:hist].gsub(/\D/,'').to_i if params[:hist]
    #Going back to a previous search
    if hist
      search_history = Session.current.searches
      if hist <= search_history.length && hist > 0
        mysearch = search_history[hist-1]
        classVariables(mysearch)
      else
        s = Search.createInitialClusters
        classVariables(s)
      end
    else
      classVariables(Search.createFromClustersAndCommit(params[:id].split('-')), Session.current.searches.last)
    end
    render 'ajax', :layout => false
  end
  
  def classVariables(search)
    Session.current.search = search
    if $SimpleLayout
      unless params[:page].nil?
        page = params[:page]
        Session.current.search.page = page
        Session.current.search.save
      else
        page = search.page
      end
      # This needs to be cleaned up later (two commits per request at the moment).
      @products = search.products.paginate :page => page, :per_page => 9
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
        s = Search.createFromClustersAndCommit(cluster.children, Session.current.searches.last)
        classVariables(s)
        render 'ajax', :layout => false
      else
        redirect_to "/compare/compare/"+cluster.children.map{|c|c.id}.join('-')
      end
    else
      redirect_to "/compare/compare/"
    end
  end

  def filter
    session = Session.current
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
      oldsearch = session.searches.last
      session.search = oldsearch
      s = Search.createFromFilters(params[:myfilter], current_search_term)
      unless s.clusters.empty?
        classVariables(s)
        render 'ajax', :layout => false
      else
        #Rollback
        session.search = oldsearch
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
    if $product_type
      if $product_type == "flooring_builddirect"
        @imglurl = "http://www.builddirect.com" + CGI.unescapeHTML(@product.imglurl.to_s)
      elsif $product_type == "Laptop"
        @imglurl = @product.imgurl.to_s
      else
        @imglurl = @product.imglurl
      end
    else
      @imglurl = @product.imglurl
    end

    @offerings = RetailerOffering.find_all_by_product_id_and_product_type(params[:id],$product_type,:order => 'priceint ASC')
    @review = Review.find_by_product_id_and_product_type(params[:id],$product_type, :order => 'helpfulvotes DESC')
    # Take out offending <br />
    if @review && @review.content
      @review.content = @review.content.gsub(/\r\&lt\;br \/\&gt\;/, '').gsub(/\t/,' ').strip
    end
    @cartridges = Compatibility.find_all_by_product_id_and_product_type(@product.id,$product_type).map{|c|Cartridge.find_by_id(c.accessory_id)}.reject{|c|!c.instock}
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
