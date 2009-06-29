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
      redirect_to "/#{@pt.pluralize.downcase}/representative(@session)/"+cluster_ids.join('/')
    else
      flash[:error] = "There are not 9 original clusters"
      redirect_to '/error'
    end
  end
  
  def list
    @session = Session.find(session[:user_id])
    @pt = session[:productType] || $DefaultProduct
    @dbfeat = {}
  
    DbFeature.find_all_by_product_type(@pt).each {|f| @dbfeat[f.name] = f}
    #Previously clicked product
    #@searches  = [Search.find_by_session_id(@session.id, :order => 'updated_at desc')]
    @allSearches = Search.find_all_by_session_id(@session.id, :order => 'updated_at ASC') #, :conditions => "updated_at > \'#{1.hour.ago}\'")
   
    @picked_products = @session.saveds.map {|s| @pt.constantize.find(s.product_id)}
    
      @z = zipStack(@allSearches)  
    unless ((@z.empty?) || (@z.nil?))
      debugger
      @layer = @z[0].layer
      l = @layer
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
    
#    pid = @s.parent_id
#   
#   unless pid==0
#     cluster = (@pt+'Cluster').constantize.find(pid)
#     layer = cluster.layer
#   
#     #  @r = Search.copySearch(@s)
#     while (layer > 1)
#         mycluster = 'c0'
#         ppid = cluster.parent_id
#      # children of grandparents           
#         cs = (@pt+'Cluster').constantize.find_all_by_parent_id(ppid)
#     #    cs.each do |c|
#     #      @r[mycluster] = c.id.to_s
#     #      mycluster.next!
#     #    end  
#    #     @r['parent_id'] = pid2
#    #     @r['cluster_count'] = cs.length
#    #     @r['result_count'] = cs.map{|c| c.nodes(@session).length}.sum
#          
#         @stack.unshift([cs.map{|c| c.id}])
#         pid = ppid
#         cluster = (@pt+'Cluster').constantize.find(pid)
#         layer = layer - 1 
#    #  @r = Search.copySearch(@r)  
#     end
##     @r = Search.copySearch(@s)
#
#      ppid = cluster.parent_id    
#      cs = (@pt+'Cluster').constantize.find_all_by_parent_id(ppid)
#      @stack.unshift([cs.map{|c| c.id}])
#     
#  end
 @s = Search.searchFromPath(params[:path_info], @session)
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
