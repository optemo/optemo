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
    
    #homepage
  end
  
  def compare
    @session = @@session
    @dbfeat = {}
    DbFeature.find_all_by_product_type_and_region($model.name,$region).each {|f| @dbfeat[f.name] = f}
    @s = Search.createFromPath_and_commit(params[:id].split('-'), @session.id)
      
    @dists = @s.distributions
    @picked_products = @session.saveds.map {|s| $model.find(s.product_id)}
    @allSearches = []
    @clusterDescs = @s.clusterDescription
    if @session.searchpids.blank? #|| @@session.searchpids.size > 9)
      z = Search.find_all_by_session_id(@session.id, :order => 'updated_at ASC', :conditions => "updated_at > \'#{1.hour.ago}\'")
      unless (z.nil? || z.empty?)
        @layer, @allSearches = zipStack(z) 
      end  
      #No products found
      if @s.result_count == 0
        flash[:error] = "No products were found, so you were redirected to the home page"
        redirect_to initialClusters
      end
   end  
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @plain = params[:plain].nil? ? false : true
    #Cleanse id to be only numbers
    params[:id] = params[:id][/^\d+/]
    @product = $model.find(params[:id])
    @offerings = RetailerOffering.find_all_by_product_id_and_product_type_and_region(params[:id],$model.name,$region,:order => 'priceint ASC')
    @review = Review.find_by_product_id_and_product_type(params[:id],$model.name, :order => 'helpfulvotes DESC')
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
    mypreferences = params[:mypreference]
    $model::ContinuousFeatures.each do |f|
      @@session.features.update_attribute(f+"_pref", mypreferences[f+"_pref"])
    end
    # To stay on the current page 
    redirect_to ""
  end
   
  def select
    @@session.defaultFeatures(URI.encode(params[:id]))
    render :nothing => true
  end
  
  def buildrelations
    source = params[:source]
    itemId = params[:itemId]
    # Convert the parameter string into an array of integers
    otherItems = params[:otherItems].split(",").collect{ |s| s.to_i }
    for otherItem in 0..otherItems.count-1
      # If the source is unsave i.e. a saved product has been dropped, then
      # create relations with lower as the dropped item and higher as all other saved items 
      if source == "unsave" || source == "unsaveComp"
        PreferenceRelation.createBinaryRelation(otherItems[otherItem], itemId, @@session.id, $Weight[source])
      else
        PreferenceRelation.createBinaryRelation(itemId, otherItems[otherItem], @@session.id, $Weight[source])
      end
    end    
    render :nothing => true
  end
  
  def homepage
    redirect_to initialClusters
  end
  
  private
  
  # this function gets an stack of searches and gets rid of the ones with repetitive
  # layer numbers
  def zipStack(stack)

     allSearches = []
     i=0
     until (stack[-1 -i].layer == 1)
       s = stack[-1-i]
       ls = allSearches.map{|r| r.layer}

       if (ls.index(s.layer).nil?)
          if (ls.empty?)
            allSearches.unshift(s)
          elsif (ls[0] > s.layer)
            allSearches.unshift(s) 
          end  
       end   
       i = i+1
     end    
     allSearches.unshift(stack[-1-i]) if (stack[-1-i].layer==1)  
     layer = allSearches[-1].layer

     # When can't reach the first layer in the given time frame 
     # Must create searches for higher layers
     l = allSearches[0].layer
     unless l == 1 
          pid =  allSearches[0].parent_id
          r = Search.new 
          cluster = $clustermodel.find(pid)            
          while (l>1)
             mycluster = 'c0'
             ppid = cluster.parent_id  
             cs = $clustermodel.find_all_by_parent_id(ppid)
             cs.each do |c|
               r[mycluster] = c.id.to_s
               mycluster.next!
             end  
          end   
          r['parent_id'] = pid2
          allSearches.unshift(r)
     end

     return layer, allSearches
  end
 
end
