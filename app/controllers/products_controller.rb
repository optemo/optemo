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
    @pt = session[:productType] || $DefaultProduct
    if @pt == 'Printer' && s = Search.find_by_session_id(0)
      path = s.to_s
    else
      path = PrinterCluster.find_all_by_parent_id(0, :order => 'cluster_size DESC').map{|c| c.id}.join('/')
    end
    if path
      redirect_to "/#{@pt.pluralize.downcase}/list/"+path
    else
      flash[:error] = "There was a problem selecting the initial products"
      redirect_to '/error'
    end
  end
  
  def list
    @session = Session.find(session[:user_id])
    @pt = session[:productType] || $DefaultProduct
    @dbfeat = {}
    DbFeature.find_all_by_product_type(@pt).each {|f| @dbfeat[f.name] = f}
    @s = Search.searchFromPath(params[:path_info], @session)
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @plain = params[:plain].nil? ? false : true
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    pt = session[:productType] || $DefaultProduct
    @product = $model.find(params[:id])
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
