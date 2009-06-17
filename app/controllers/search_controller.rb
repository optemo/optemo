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
      #Allow for multiple brands
      myfilter = multipleBrands(myfilter)
      #Delete blank values
      myfilter.delete_if{|k,v|v.blank?}
      myfilter.each_pair {|key, val| myfilter[key] = val.to_f if key.index('_min') || key.index('_max')}
      #Find clusters that match filtering query
      clusters = (@session.product_type+'Cluster').constantize.find_all_by_layer(1)
      clusters.delete_if{|c| c.isEmpty(myfilter,@session)}
      unless clusters.empty?
        myfilter[:filter] = true
        #Save search values
        @session.update_attributes(myfilter)
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
      cluster_ids = product_ids.map{|p|(@session.product_type+'Node').constantize.find_by_product_id(p, :order => 'cluster_id').cluster_id}
      redirect_to "/#{session[:productType].pluralize.downcase}/list/"+cluster_ids.uniq.sort[0..8].join('/')
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
end
