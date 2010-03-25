class CompareController < ApplicationController
  layout "optemo"
  require 'open-uri'
  require 'iconv'
  include CachingMemcached
  
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
    Session.current.copyfeatures #create a copy of the current filters
    if cluster_id.index('+')
      #Merged Cluster
      cluster = MergedCluster.fromIDs(cluster_id.split('+'))
    else
      #Single, normal Cluster
      cluster = findCachedCluster(cluster_id)
    end
    unless cluster.nil?
      if params[:ajax]
        s = Search.createFromClustersAndCommit(cluster.children)
        Session.current.commitFilters(s.id)
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
    if params[:myfilter].nil?
      #No post info passed
      render :text =>  "[ERR]Search could not be completed."
    else
      #Fixes the fact that the brand selector value is not used
      params[:myfilter].delete("brand1")
      Session.current.search = Session.current.searches.last #My last search used for finding the right filters
      session.updateFilters(params[:myfilter])
      clusters = session.clusters
      unless clusters.empty?
        s = Search.createFromClustersAndCommit(clusters)
        session.commitFilters(s.id)
        classVariables(s)
        render 'ajax', :layout => false
      else
        session.rollback
        Session.current.search = session.searches.last
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
    @product = findCachedProduct(params[:id])
    if $model.name
      @imglurl = "/images/" + $model.name.downcase + "s/" + @product.id.to_s + "_l.jpg"
    else
      @imglurl = "/images/printers/" + @product.id.to_s + "_l.jpg"
    end

    @offerings = RetailerOffering.find_all_by_product_id_and_product_type_and_region(params[:id],$model.name,$region,:order => 'priceint ASC')
    @review = Review.find_by_product_id_and_product_type(params[:id],$model.name, :order => 'helpfulvotes DESC')
    # Take out offending <br />
    if @review && @review.content
      @review.content = @review.content.gsub(/\r\&lt\;br \/\&gt\;/, '').gsub(/\t/,' ').strip
    end
    @cartridges = Compatibility.find_all_by_product_id_and_product_type(@product.id,$model.name).map{|c|Cartridge.find_by_id(c.accessory_id)}.reject{|c|!c.instock}
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
      product_ids = $model.search_for_ids(params[:search].downcase, :per_page => 10000, :star => true)
      current_version = Session.current.version
      nodes = product_ids.map{|p| findCachedNodeByPID(p) }.compact
      
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
end
