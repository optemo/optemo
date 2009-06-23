class ProductsController < ApplicationController
  #require 'rubygems'
  #require 'config/environment'
  #require 'scrubyt'
  layout 'optemo'
  require 'open-uri'
  
  # GET /products
  # GET /products.xml
  def index
    mysession = Session.find(session[:user_id])
    mysession.clearFilters
    #c = CQuery.new(session[:productType] || $DefaultProduct)
    @pt = session[:productType] || $DefaultProduct
    cluster_ids = (@pt+'Cluster').constantize.find_all_by_parent_id(0, :order => 'cluster_size DESC').map{|c| c.id}
    if cluster_ids.length == 9
      redirect_to "/#{@pt.pluralize.downcase}/list/"+cluster_ids.join('/')
    else
      flash[:error] = "There are not 9 original clusters"
      redirect_to '/error'
    end
  end
  
  def list
    @session = Session.find(session[:user_id])
    @pt = session[:productType] || $DefaultProduct
    @model = @pt.constantize
    @dbfeat = {}
    DbFeature.find_all_by_product_type(@pt).each {|f| @dbfeat[f.name] = f}
    #Previously clicked product
    @searches = [Search.find_by_session_id(@session.id, :order => 'updated_at desc')]
    @s = Search.searchFromPath(params[:path_info], @session)
    @picked_products = @session.saveds.map {|s| @pt.constantize.find(s.product_id)}
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @plain = params[:plain].nil? ? false : true
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    pt = session[:productType] || $DefaultProduct
    @model = pt.constantize
    @product = @model.find(params[:id])
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
end
