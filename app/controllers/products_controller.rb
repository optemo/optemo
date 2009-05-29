class ProductsController < ApplicationController
  #require 'rubygems'
  #require 'config/environment'
  #require 'scrubyt'
  layout 'optemo'
  require 'open-uri'
  
  # GET /products
  # GET /products.xml
  def index
    productType = session[:productType] || $DefaultProduct
    reset_session
    session[:productType] = productType
    c = CQuery.new(session[:productType])
    if c.valid
      redirect_to "/#{session[:productType].pluralize.downcase}/list/"+c.to_s
    else
      flash[:error] = c.to_s
    end
  end
  
  def list
    @session = Session.find(session[:user_id])
    @dbprops = DbProperty.find_by_name(session[:productType].constantize.name)
    #Check for search keyword
    if params[:path_info][-2] == 's'
      cluster_ids = params[:path_info][0..-3].map{|p|p.to_i}
      searchterm = params[:path_info][-1].gsub(/[\W]/,'')
      @c = CQuery.new(session[:productType],cluster_ids,@session,searchterm) #C-code wrapper
    else
      @c = CQuery.new(session[:productType], params[:path_info].map{|p|p.to_i},@session) #C-code wrapper
    end
    if !@c.valid
      flash[:error] = @c.to_s
      redirect_to '/error'
    end
    #Saved Bar variables
    @picked_products = @session.saveds.map {|s| session[:productType].constantize.find(s.product_id)}
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
    @product = session[:productType].constantize.find(params[:id])
    @offerings = RetailerOffering.find_all_by_product_id_and_product_type(params[:id],session[:productType])
    #Session Tracking
    s = Viewed.new
    s.session_id = session[:user_id]
    s.product_id = @product.id
    s.save
    respond_to do |format|
      format.html { if @plain
                      render :layout => false
                    else
                      render :http => 'show' 
                    end }
      format.xml  { render :xml => @product }
    end
  end

  # GET /products/new
  # GET /products/new.xml
  def new
    @product = session[:productType].constantize.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @product }
    end
  end

  # GET /products/1/edit
  def edit
    @product = session[:productType].constantize.find(params[:id])
  end

  # POST /products
  # POST /products.xml
  def create
    @product = session[:productType].constantize.new(params[:product])

    respond_to do |format|
      if @product.save
        flash[:notice] = 'Product was successfully created.'
        format.html { redirect_to(@product) }
        format.xml  { render :xml => @product, :status => :created, :location => @product }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /products/1
  # PUT /products/1.xml
  def update
    @product = session[:productType].constantize.find(params[:id])

    respond_to do |format|
      if @product.update_attributes(params[:product])
        flash[:notice] = 'Product was successfully updated.'
        format.html { redirect_to(@product) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.xml
  def destroy
    @product = session[:productType].constantize.find(params[:id])
    @product.destroy

    respond_to do |format|
      format.html { redirect_to(products_url) }
      format.xml  { head :ok }
    end
  end
  
  def destroy_all
    @products = session[:productType].constantize.find(:all)
    @products.each do |product|
      product.destroy
    end
    redirect_to products_url
  end

end
