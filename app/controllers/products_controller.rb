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
    c = CQuery.new(session[:productType] || $DefaultProduct)
    if c.valid
      redirect_to "/#{c.product_type.pluralize.downcase}/list/"+c.to_s
    else
      flash[:error] = c.to_s
      redirect_to '/error'
    end
  end
  
  def list
    @session = Session.find(session[:user_id])
    @pt = session[:productType] || $DefaultProduct
    @dbprops = DbProperty.find_by_name(@pt.constantize.name)
    #Check for search keyword
    if params[:path_info][-2] == 's'
      cluster_ids = params[:path_info][0..-3].map{|p|p.to_i}
      searchterm = URI.decode(params[:path_info][-1])
      @c = CQuery.new(@pt,cluster_ids,@session,searchterm) #C-code wrapper
    else
      @c = CQuery.new(@pt, params[:path_info].map{|p|p.to_i},@session) #C-code wrapper
    end
    if !@c.valid
      flash[:error] = @c.to_s
      redirect_to '/error'
    end
    #Saved Bar variables
    @picked_products = @session.saveds.map {|s| @pt.constantize.find(s.product_id)}
    #Previously clicked product
    #@searches = []
    #if session[:search_id]
    #  @search = Search.find(session[:search_id]) 
    #  currentsearch = @search
    #  while (!currentsearch.parent_id.nil?) do
    #    @searches<<currentsearch.id
    #     currentsearch = Search.find(currentsearch.parent_id)
    #  end
    #end
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @plain = params[:plain].nil? ? false : true
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
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
end
