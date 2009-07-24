class SearchController < ApplicationController
  
  # TODO this is for testing
  # Disable csrf protection on controller-by-controller basis:
  skip_before_filter :verify_authenticity_token
  
  def filter
    @session = Session.find(session[:user_id])
    myfilter = params[:myfilter]
    if myfilter.nil?
      #No post info passed
      flash[:error] = "Search could not be completed."
      redirect_to "/#{$model.urlname}/compare/"+@session.oldclusters.map{|c|c.id}.join('-')
    else
      #Allow for multiple brands
      myfilter = multipleBrands(myfilter)
      mysession = @session.createFromFilters(myfilter)
      clusters = mysession.clusters
      unless clusters.empty?
        mysession.commit
        redirect_to "/#{$model.urlname}/compare/"+clusters.map{|c|c.id}.join('-')
      else
        flash[:error] = "No products were found."
        redirect_to "/#{$model.urlname}/compare/"+@session.oldclusters.map{|c|c.id}.join('-')
      end
    end
  end
  
  def find
    @session = Session.find(session[:user_id])
    sphinx = searchSphinx(params[:search])
    product_ids = sphinx.results.delete_if{|r|r[0] != $model.name}.map{|r|r[1]}
    current_version = $clustermodel.last.version
    nodes = product_ids.map{|p| $nodemodel.find_by_product_id_and_version(p, current_version)}.compact
    cluster_ids = nodes.map{|n|n.cluster_id}
    if cluster_ids.length == 0
      flash[:error] = "No products were found."
      if request.referer.nil?
        redirect_to "/#{$model.urlname}"
      else
        redirect_to request.referer
      end
    else
      @session.clearFilters
      @session.searchterm = params[:search]
      @session.searchpids = nodes.map{|p| "product_id = #{p.product_id}"}.join(' OR ')
      @session.save
      clusters = cluster_ids.sort.uniq[0..8]
      redirect_to "/#{$model.urlname}/compare/"+clusters.join('-')
    end
  end
   
  def delete
    @session = Session.find(session[:user_id])
    @session.searchterm = ""
    @session.searchpids = ""
    @session.save
    redirect_to initialClusters
  end
  
  private
  
  def searchSphinx(searchterm)
    search = Ultrasphinx::Search.new(:query => searchterm, :per_page => 10000)
    search.run(false)
    search
  end
  
  def multipleBrands(myfilter)
    new_brand = myfilter[:brand]
    if !myfilter[:Xbrand].blank?
      #Remove a brand
      myfilter[:brand] = @session.features.brand.split('*').delete_if{|b|b == myfilter[:Xbrand]}.join('*')
      myfilter[:brand] = 'All Brands' if myfilter[:brand].blank?
    elsif new_brand != "All Brands" && new_brand != "Add Another Brand"
      old_brand = @session.features.brand
      #Add a brand
      if myfilter[:brand].nil?
        myfilter[:brand] = old_brand if old_brand != "All Brands" && old_brand != "Add Another Brand"
      else
        myfilter[:brand]+= '*'+old_brand if !old_brand.blank? && old_brand != "All Brands" && old_brand != "Add Another Brand"
      end
    elsif new_brand == "Add Another Brand"
      myfilter[:brand] = @session.features.brand
    end
    myfilter.delete('Xbrand') if myfilter[:Xbrand]
    myfilter
  end
end
