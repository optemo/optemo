class SearchController < ApplicationController
  
  # TODO this is for testing
  # Disable csrf protection on controller-by-controller basis:
  skip_before_filter :verify_authenticity_token
  
  def filter
    myfilter = params[:myfilter]
    if myfilter.nil?
      #No post info passed
      flash[:error] = "Search could not be completed."
      redirect_to "/#{session[:productType].pluralize.downcase}/list/"+params[:path_info].join('/')
    else
      @session = Session.find(session[:user_id])
      @model = @session.product_type.constantize
      #Allow for multiple brands
      myfilter = multipleBrands(myfilter)
      #Delete blank values
      myfilter.delete_if{|k,v|v.blank?}
      myfilter.each_pair {|key, val| myfilter[key] = val.to_f if key.index('_min') || key.index('_max')}
      #Fix price, because it's stored as int in db
      myfilter[:price_max] = (myfilter[:price_max]*100).to_i if myfilter[:price_max]
      myfilter[:price_min] = (myfilter[:price_min]*100).to_i if myfilter[:price_min]
      myfilter = handle_false_booleans(myfilter)
      
      #debugger
      
      #Find clusters that match filtering query
      model = (@session.product_type+'Cluster').constantize
      if expandedFiltering?(myfilter)
        #Search is expanded, so use all products to begin with
        clusters = model.find_all_by_layer(1)
        clusters.delete_if{|c| c.isEmpty(@session,myfilter)}
      else
        #Search is narrowed, so use current products to begin with
        clusters = []
        params[:path_info].each do |cid|
           c = model.find(cid)
           clusters << c unless c.isEmpty(@session,myfilter)
        end
      end
      unless clusters.empty?
        myfilter[:filter] = true
        #Save search values
        @session.update_attributes(myfilter)
        clusters = fillDisplay(clusters)
        redirect_to "/#{session[:productType].pluralize.downcase}/list/"+clusters.map{|c|c.id}.join('/')
      else
        flash[:error] = "No products found."
        redirect_to "/#{session[:productType].pluralize.downcase}/list/"+params[:path_info].join('/')
      end
    end
  end
  
  def find
    @session = Session.find(session[:user_id])
    sphinx = searchSphinx(params[:search])
    product_ids = sphinx.results.delete_if{|r|r.class.name != @session.product_type || !r.myvalid?}.map{|p|p.id}
    if product_ids.length == 0
      flash[:error] = "No products were found"
      redirect_to "/#{session[:productType].pluralize.downcase}/list/"+params[:path_info].join('/')
    else
      @session.searchterm = params[:search]
      @session.searchpids = product_ids.map{|id| "product_id = #{id}"}.join(' OR ')
      @session.save
      model = (@session.product_type+'Node').constantize
      cluster_ids = product_ids.map{|p| model.find_by_product_id(p, :order => 'cluster_id').cluster_id}
      model = (@session.product_type+'Cluster').constantize
      clusters = fillDisplay(cluster_ids.uniq.sort[0..8].compact.map{|c|model.find(c)})
      redirect_to "/#{session[:productType].pluralize.downcase}/list/"+clusters.map{|c|c.id}.join('/')
    end
  end
  
  def delete
    @session = Session.find(session[:user_id])
    @session.searchterm = ""
    @session.searchpids = ""
    @session.save
    redirect_to "/#{session[:productType].pluralize.downcase}/"
  end
  private
  
  def searchSphinx(searchterm)
    search = Ultrasphinx::Search.new(:query => searchterm, :per_page => 10000)
    search.run
    search
  end
  
  def multipleBrands(myfilter)
    new_brand = myfilter[:brand]
    if !myfilter[:Xbrand].blank?
      #Remove a brand
      myfilter[:brand] = @session.brand.split('*').delete_if{|b|b == myfilter[:Xbrand]}.join('*')
      myfilter[:brand] = 'All Brands' if myfilter[:brand].blank?
      @session.update_attribute('brand',myfilter[:brand])
    elsif new_brand != "All Brands" && new_brand != "Add Another Brand"
      old_brand = @session.brand
      #Add a brand
      if myfilter[:brand].nil?
        myfilter[:brand] = old_brand if old_brand != "All Brands" && old_brand != "Add Another Brand"
      else
        myfilter[:brand]+= '*'+old_brand if !old_brand.blank? && old_brand != "All Brands" && old_brand != "Add Another Brand"
      end
    elsif new_brand == "Add Another Brand"
      myfilter[:brand] = @session.brand
    end
    myfilter.delete('Xbrand') if myfilter[:Xbrand]
    myfilter
  end
  
  def splitClusters(clusters)
    while clusters.length != 9
      clusters.sort! {|a,b| b.size(@session) <=> a.size(@session)}
      clusters = split(clusters.shift.children(@session)) + clusters
    end
    clusters.sort! {|a,b| b.size(@session) <=> a.size(@session)}
  end
  
  def split(children)
    return children if children.length == 1
    children.sort! {|a,b| b.size(@session) <=> a.size(@session)}
    [children.shift, MergedCluster.new(children)]
  end
  
  def expandedFiltering?(filtering)
    filtering.keys.each do |key|
      if key.index(/(.+)_min/)
        fname = Regexp.last_match[1]
        max = fname+'_max'
        maxv = @session.send(max.intern)
        next if maxv.nil?
        oldrange = maxv - @session.send(key.intern)
        newrange = filtering[max] - filtering[key]
        return true if newrange > oldrange
      end
    end
    false
  end
  
  def fillDisplay(clusters)
    if clusters.length < 9
      if clusters.map{|c| c.size(@session)}.sum >= 9
        clusters = splitClusters(clusters)
      else
        #Display only the deep children
        clusters = clusters.map{|c| c.deepChildren(@session)}.flatten
      end
    end
    clusters
  end
  
  def handle_false_booleans(myfilter)
    @model::BinaryFeatures.each do |f|
      if myfilter[f] == '0' 
        myfilter.delete(f) 
        @session.update_attribute(f,nil) if @session.send(f.intern) == true
      end
    end
    myfilter
  end
end
