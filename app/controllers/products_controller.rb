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
    homepage
  end
  
  def list
    @session = Session.find(session[:user_id])
    @pt = session[:productType] || $DefaultProduct
    @dbfeat = {}
    @s = Search.searchFromPath(params[:path_info], @session)
    DbFeature.find_all_by_product_type(@pt).each {|f| @dbfeat[f.name] = f}
    @allSearches = Search.find_all_by_session_id(@session.id, :order => 'updated_at ASC', :conditions => "updated_at > \'#{1.minute.ago}\'")
    @picked_products = @session.saveds.map {|s| $model.find(s.product_id)}
    @z = zipStack(@allSearches) 
    unless ((@z.empty?) || (@z.nil?))
      @layer = @z[-1].layer
      l = @z[0].layer
      unless l == 1 # can't reach the first layer in the given time frame
           pid =  @z[0].parent_id
           r = Search.new 
           cluster = (@pt+'Cluster').constantize.find(pid)            
           while (l>1)
              mycluster = 'c0'
              ppid = cluster.parent_id  
              cs = (@pt + 'Cluster').constantize.find_all_by_parent_id(ppid)
              cs.each do |c|
                r[mycluster] = c.id.to_s
                mycluster.next!
              end  
           end   
           r['parent_id'] = pid2
           @z.unshift(r)
      end
    end   
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
  
  private
  
  def homepage
    mysession = Session.find(session[:user_id])
    mysession.clearFilters
    @pt = session[:productType] || $DefaultProduct
    if @pt == 'Printer' && s = Search.find_by_session_id(0)
      path = s.cluster_count.times.map{|i| s.send(:"c#{i}")}.join('/')
    else
      path = $clustermodel.find_all_by_parent_id(0, :order => 'cluster_size DESC').map{|c| c.id}.join('/')
    end
    if path
      redirect_to "/#{@pt.pluralize.downcase}/list/"+path
    else
      flash[:error] = "There was a problem selecting the initial products"
      redirect_to '/error'
    end
  end
end
