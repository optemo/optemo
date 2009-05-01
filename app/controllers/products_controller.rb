class ProductsController < ApplicationController
  #require 'rubygems'
  #require 'config/environment'
  #require 'scrubyt'
  layout 'optemo'
  require 'open-uri'
  
  # GET /products
  # GET /products.xml
  def index
    productType = session[:productType]
    reset_session
    session[:productType] = productType
  end
  
  def list
    @session = Session.find(session[:user_id])
    #Filtering variables
    #if session[:search_id] && Search.find(session[:search_id]).URL == params[:path_info].join('/')
    #  @search = Search.find(session[:search_id])
    #else
    #  @search = initialize_search
    #end
    chosen = YAML.load(@session.chosen) if @session.chosen
    @dbprops = DbProperty.find_by_name(session[:productType].constantize.name)
    #Navigation Variables
    @products = []
    @clusters = []
    @desc = []
    counter = 0
    params[:path_info].collect do |num|
      @products << session[:productType].constantize.find(num)
      if num.to_i == @session.send(('i'+counter.to_s).intern)
        #debugger
        myc = chosen.find{|c| c[:cluster_id] == @session.send(('c'+counter.to_s).intern)} if chosen
        if myc.nil?
          #Otherwise fill in a null value
          @desc << nil
          @clusters << nil
        else
          #Find the cluster's description
          @clusters << myc.delete('cluster_id')
          @desc << myc.to_a
        end
      end
      counter += 1
    end
    #Saved Bar variables
    @picked_products = @session.saveds.map {|s| session[:productType].constantize.find(s.product_id)}
    #Previously clicked product
    @search = Search.find(session[:search_id]) if session[:search_id]
    @product = session[:productType].constantize.find(@search.product_id) if @search && @search.product_id
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
    end
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
