class CompareController < ApplicationController
  layout "optemo"
  require 'open-uri'
  require 'iconv'
  
  def index
    if Session.isCrawler?(request.user_agent) || params[:ajax]
      Search.createInitialClusters
    else
      @indexload = true
    end
    if params[:ajax]
      render 'ajax', :layout => false
    else
      render 'compare'
    end
  end
  
  def compare
    hist = params[:hist].gsub(/\D/,'').to_i if params[:hist]
    #Going back to a previous search
    if hist
      search_history = Session.current.searches
      if hist < search_history.length && hist > 0
        mysearch = search_history[hist-1]
        Session.current.keywordpids = mysearch.searchpids 
        Session.current.keyword = mysearch.searchterm
        classVariables(mysearch)
      else
        Search.createInitialClusters
      end
    else
      classVariables(Search.createFromClustersAndCommit(params[:id].split('-')))
    end
    #No products found
    if Session.current.search.result_count == 0
      flash[:error] = "No products were found, so you were redirected to the home page"
      redirect_to "/compare/compare/"
    end
    if hist
      render 'ajax', :layout => false
    end
  end
  
  def classVariables(search)
    Session.current.search = search
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
        s = Search.createFromClustersAndCommit(cluster.children)
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
    if params[:myfilter].nil?
      #No post info passed
      render :text =>  "[ERR]Search could not be completed."
    else
      #Fixes the fact that the brand selector value is not used, among other selectors
      params[:myfilter].delete("brand1")
      # These were introduced for Flooring
      params[:myfilter].delete("species1")
      params[:myfilter].delete("colorrange1")
      params[:myfilter].delete("feature1")
      
      s = Search.createFromFilters(params[:myfilter])
      unless s.clusters.empty?
        s.commitfilters
        classVariables(s)
        render 'ajax', :layout => false
      else
        #Rollback
        Session.current.search = Session.current.searches.last
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
      if $product_type == "Flooring"
        imagestring = CGI.unescapeHTML(@product.imagelink.to_s).split("&")
        imagestring[0] = imagestring[0].split("?")[0] + "?" + imagestring[1]
        imagestring.delete_at(1)
        imagestring = imagestring.join("&")
        @imglurl = "http://www.builddirect.com" + imagestring
      elsif $product_type == "Laptop"
        @imglurl = @product.imgurl.to_s
      else
        @imglurl = "/images/" + $product_type.downcase + "s/" + @product.id.to_s + "_l.jpg"
      end
    else
      @imglurl = "/images/printers/" + @product.id.to_s + "_l.jpg"
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
  
  def find
    if params[:search].blank? && params[:ajax]
      Search.createInitialClusters
      render 'ajax', :layout => false
    else
      product_ids = Product.search_for_ids(params[:search].downcase, :per_page => 10000, :star => true)
      current_version = Session.current.version
      nodes = product_ids.map{|p| Node.byproduct(p) }.compact
      
      if nodes.length == 0
        if params[:ajax]
          @errortype = "search"
          render 'error', :layout=>true
        else
          flash[:error] = "No products were found."
          if request.referer.nil?
            redirect_to "/compare"
          else
            redirect_to request.referer
          end
        end
      else
        Search.createInitialClusters
        Session.current.update_attribute('filter', true)
        Session.current.keyword = params[:search]
        Session.current.keywordpids = nodes.map{|p| "product_id = #{p.product_id}"}.join(' OR ')
        
        if params[:ajax]
          classVariables(Search.createFromKeywordSearch(nodes))
          render 'ajax', :layout => false
        else
          #This is broken without AJAX because searchterm is not updated in Search object
          redirect_to "/compare/compare/"+nodes.map{|n|n.cluster_id}.join('-')
        end
      end
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
