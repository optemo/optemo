class ProductsController < ApplicationController
  #require 'rubygems'
  #require 'config/environment'
  #require 'scrubyt'
  layout 'optemo'
  require 'open-uri'
  
  # GET /products
  # GET /products.xml
  def index
    @link = initialClusters
    homepage
  end
  
  def list
    @session = Session.find(session[:user_id])
    @pt = session[:productType] || $DefaultProduct
    @dbfeat = {}
    DbFeature.find_all_by_product_type(@pt).each {|f| @dbfeat[f.name] = f}
    @s = Search.searchFromPath(params[:path_info], @session.id)
    @picked_products = @session.saveds.map {|s| $model.find(s.product_id)}
    @allSearches = []
    z = Search.find_all_by_session_id(@session.id, :order => 'updated_at ASC', :conditions => "updated_at > \'#{1.hour.ago}\'")
    unless (z.nil? || z.empty?)
      @layer, @allSearches = zipStack(z) 
    end  
    #No products found
    if @s.result_count == 0
      flash[:error] = "No products were found, so you were redirected to the home page"
      homepage
    end
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @plain = params[:plain].nil? ? false : true
    #Cleanse id to be only numbers
    params[:id] = params[:id][/^\d+/]
    pt = session[:productType] || $DefaultProduct
    @product = pt.constantize.find(params[:id])
    @offerings = RetailerOffering.find_all_by_product_id_and_product_type(params[:id],pt)
    #Session Tracking
    s = Viewed.new
    s.session_id = session[:user_id]
    s.product_id = @product.id
    s.save
    respond_to do |format|
      format.html { if @plain
                      render :layout => false
                    else
                      render :http => 'show' , :layout => 'optemo'
                    end }
      format.xml  { render :xml => @product }
    end
  end
  
  def preference
     @session = Session.find(session[:user_id])
     mypreferences = params[:mypreference]
     $model::ContinuousFeatures.each do |f|
       @session.features.update_attribute(f+"_pref", mypreferences[f+"_pref"])
     end
     # To stay on the current page 
     redirect_to ""
   end
   
  def select
    @session = Session.find(session[:user_id])
    @session.defaultFeatures(URI.encode(params[:id]))
  end
  
  def buildrelations
    @session = Session.find(session[:user_id])
    source = params[:source]
    itemId = params[:itemId]
    # Convert the parameter string into an array of integers
    otherItems = params[:otherItems].split(",").collect{ |s| s.to_i }
    for otherItem in 0..otherItems.count-1
      # If the source is unsave i.e. a saved product has been dropped, then
      # create relations with lower as the dropped item and higher as all other saved items 
      if source == "unsave"
        PreferenceRelation.createBinaryRelation(otherItems[otherItem], itemId, @session.id, $Weight[source])
      else
        PreferenceRelation.createBinaryRelation(itemId, otherItems[otherItem], @session.id, $Weight[source])
      end
    end    
  end
 
  private
  
  def homepage
    path = initialClusters
    if path
      redirect_to path
    else
      flash[:error] = "There was a problem selecting the initial products"
      redirect_to '/error'
    end
  end
  
  def initialClusters
    mysession = Session.find(session[:user_id])
    mysession.clearFilters
    @pt = session[:productType] || $DefaultProduct
    if @pt == 'Printer' && s = Search.find_by_session_id(0)
      path = 0.upto(s.cluster_count-1).map{|i| s.send(:"c#{i}")}.join('/')
    else
      current_version = $clustermodel.last.version
      path = $clustermodel.find_all_by_parent_id_and_version(0, current_version, :order => 'cluster_size DESC').map{|c| c.id}.join('/')
      #path = $clustermodel.find_all_by_parent_id(0, :order => 'cluster_size DESC').map{|c| c.id}.join('/')
    end
    "/#{@pt.pluralize.downcase}/list/"+path
  end
end
