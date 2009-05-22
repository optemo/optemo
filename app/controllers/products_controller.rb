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
    @dbprops = DbProperty.find_by_name(session[:productType].constantize.name)
    #Navigation Variables
    @products = [] #The product IDs
    @clusters = [] #The cluster IDs
    @desc = [] #The cluster indicator variables
    @clustergraph = [] #The graph describing the cluster
    @subclusters = [] #The subclusters
    params[:path_info].collect do |num|
      @clusters << (session[:productType]+"Cluster").constantize.find(num)
    end
    getClusterinfo #C-code wrapper
    #Saved Bar variables
    @picked_products = @session.saveds.map {|s| session[:productType].constantize.find(s.product_id)}
    #Previously clicked product
    @searches = []
    if session[:search_id]
      @search = Search.find(session[:search_id]) 
      currentsearch = @search
      while (!currentsearch.parent_id.nil?) do
        @searches<<currentsearch.id
         currentsearch = Search.find(currentsearch.parent_id)
      end
    end
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
  
  private
  def getClusterinfo
    #Send info request
    q = {"cluster_id" => params[:path_info].map{|p|p.to_i}}
    myparams = q.to_yaml
    #debugger
    #Input
#         cluster_id :array
    #@output = %x["#{RAILS_ROOT}/lib/c_code/clusteringCode/codes/connect" "#{myparams}"]
    #options = YAML.load(@output)
    #Output structure
#        result_count :integer --now current page
#        products :array --now current page
#        clusters :array  #only for filtering
#        clusterdetails : array of hash
#          cluster_id :int
#          cluster_count :int
#          clusters :array
#          %feature :0,1,2,3
#        %feature_min :int --now current page
#        %feature_max :int --now current page
#        %feature_hist :string --now current page
    options = {'result_count' => 420, 'products' => [14,15,16,31,25,19,20,21,22], 'clusters' => [450,451,446,449,447,444,445,448,443], 
      'clusterdetails' => [{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1}],
      'ppm_max' => 24, 'ppm_min' => 4, 'itemwidth_min' => 12, 'itemwidth_max' => 2000, 'paperinput_min' => 100, 'paperinput_max' => 500,
      'resolutionarea_min' => 600, 'resolutionarea_max' => 3000000, 'price_min' => 8000, 'price_max' => 800000}
    #debugger
    #parse the new ids
    if options.blank? || options['result_count'].nil? || (options['result_count'] > 0 && options['products'].nil?)
      flash[:error] = "We're having problems with our database."
      options = {'result_count' => 0}
    elsif options['result_count'] == 0
      flash[:error] = "No products were found"
    else
      results = options['result_count'] < 9 ? options['result_count'] : 9
      #Pop array of products and clusters
      newproducts = options.delete('products')
      options.delete('clusters')
      results.times do 
        @products << (session[:productType]).constantize.find(newproducts.pop)
      end
      options.delete('clusterdetails').each do |myc|
        if myc.nil?
          #Otherwise fill in a null value
          @desc << nil
        else
          #Find the cluster's description
          cluster_id = myc.delete('cluster_id')
          realc = (session[:productType]+"Cluster").constantize.find(cluster_id)
          currentclustergraph = []
          (session[:productType].constantize::MainFeatures+["price"]).each {|name|
            min = name+'_min'
            max = name+'_max'
            if name == "price"
                prop = DbProperty.find_by_name(session[:productType])
                fmax = prop.price_max
                fmin = prop.price_min
            else
                feat = DbFeature.find_by_name(name)
                fmax = feat.max
                fmin = feat.min
            end
            #Normalize features values
            mymin = (realc.send(min.intern) - fmin) / (fmax - fmin)
            mymax = (realc.send(max.intern) - fmin) / (fmax - fmin)
            currentclustergraph << [mymin.round(2),(mymax-mymin).round(2)]
          }
          @clustergraph << currentclustergraph
          @subclusters << myc.delete('clusters').join('/')
          @desc << myc.to_a
        end
      end
      @result_count = options.delete('result_count')
      @filterinfo = options
    end
  end
end
