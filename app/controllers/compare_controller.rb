class CompareController < ApplicationController
  layout "optemo"
  require 'open-uri'
  include CachingMemcached
  
  def index
    @session = @@session
    classVariables(Search.createFromClustersAndCommit(initialClusters, @session, @@keywordsearch, @@keyword))
    if params[:ajax]
      render 'ajax', :layout => false
    else
      render 'compare'
    end
  end
  
  def compare
    @session = @@session
    classVariables(Search.createFromClustersAndCommit(params[:id].split('-'), @session, @@keywordsearch, @@keyword))
    #No products found
    if @s.result_count == 0
      flash[:error] = "No products were found, so you were redirected to the home page"
      redirect_to "/compare/compare/"+initialClusters.join('-')
    end
  end
  
  def classVariables(search)
    @s = search
  end
  
  def sim
    @session = @@session
    cluster_id = params[:id]
    if cluster_id.index('+')
      cluster_id.gsub(/[^(\d|+)]/,'') #Clean URL input
      #Merged Cluster
      cluster = MergedCluster.fromIDs(cluster_id.split('+'),@session,@@keywordsearch)
    else
      #Single, normal Cluster
      cluster = findCachedCluster(cluster_id)
    end
    unless cluster.nil?
      if params[:ajax]
        classVariables(Search.createFromClustersAndCommit(cluster.children(@session, @@keywordsearch),@session,@@keywordsearch, @@keyword))
        render 'ajax', :layout => false
      else
        redirect_to "/compare/compare/"+cluster.children(@session, @@keywordsearch).map{|c|c.id}.join('-')
      end
    else
      redirect_to initialClusters
    end
  end

  def filter
    @session = @@session
    if params[:myfilter].nil?
      #No post info passed
      render :text =>  "[ERR]Search could not be completed."
    else
      #Fixes the fact that the brand selector value is not used
      params[:myfilter].delete("brand1")
      @session.updateFilters(params[:myfilter])
      clusters = @session.clusters(@@keywordsearch)
      unless clusters.empty?
        s = Search.createFromClustersAndCommit(clusters,@session,@@keywordsearch, @@keyword)
        @session.commitFilters(s.id)
        classVariables(s)
        render 'ajax', :layout => false
      else
        @session.rollback
        @s = @session.searches.last
        @errortype = "filter"
        render 'error', :layout=>true
      end
    end
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @session = @@session
    @plain = params[:plain].nil? ? false : true
    
    #Cleanse id to be only numbers
    params[:id] = params[:id][/^\d+/]
    @product = $model.find(params[:id])
    
    if $model.name == "Camera"
      @imglurl = "/images/cameras/" + @product.id.to_s + "_l.jpg"
    elsif $model.name == "Printer"
      @imglurl = "/images/printers/" + @product.id.to_s + "_l.jpg"
    else
      @imglurl = "/images/printers/" + @product.id.to_s + "_l.jpg"
    end    
    
# => Caching:
#    @product = cache([$model.name, params[:id]]) do
#      $model.find(params[:id])
#    end
    @offerings = RetailerOffering.find_all_by_product_id_and_product_type_and_region(params[:id],$model.name,$region,:order => 'priceint ASC')
    @review = Review.find_by_product_id_and_product_type(params[:id],$model.name, :order => 'helpfulvotes DESC')
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
    @session = @@session
    if params[:search].blank? && params[:ajax]
      classVariables(Search.createFromClustersAndCommit(initialClusters, @session, @@keywordsearch, @@keyword))
      render 'ajax', :layout => false
    else
      sphinx = $model.search(params[:search],:per_page => 10000)
      product_ids = sphinx.results[:matches].map{|i|i[:doc]}
      current_version = $clustermodel.find_last_by_region($region).version
      nodes = product_ids.map{|p| $nodemodel.find_by_product_id_and_version_and_region(p, current_version, $region)}.compact
      cluster_ids = nodes.map{|n|n.cluster_id}
      if cluster_ids.length == 0
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
        @session.clearFilters
        @session.update_attribute('filter', true)
        clusters = cluster_ids.sort.uniq[0..8]
        if params[:ajax]
          searchpids = nodes.map{|p| "product_id = #{p.product_id}"}.join(' OR ')
          keyword = params[:search]
          classVariables(Search.createFromClustersAndCommit(clusters, @session, searchpids, keyword))
          render 'ajax', :layout => false
        else
          #This is broken without AJAX because searchterm is not updated in Search object
          redirect_to "/compare/compare/"+clusters.join('-')
        end
      end
    end
  end
  
  def back
    @session = @@session
    #Remove last selection
    destroyed_search = @session.searches.last.destroy.id
    feature = $featuremodel.find(:first, :conditions => ["session_id = ? and search_id = ?", @session.id,destroyed_search])
    feature.destroy if feature
    newsearch = @session.searches.last
    #In case back button is hit in the beginning
    newsearch = Search.createFromClustersAndCommit(initialClusters, @session, @@keywordsearch, @@keyword) if newsearch.nil?
    classVariables(newsearch)
    render 'ajax', :layout => false
  end
  
  private
  
  def searchSphinx(searchterm)
    search = Ultrasphinx::Search.new(:query => searchterm, :per_page => 10000)
    search.run(false)
    search
  end
 
end
