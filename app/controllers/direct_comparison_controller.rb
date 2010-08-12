class DirectComparisonController < ApplicationController
# Compares products selected for comparison ('saved' products)
  include CachingMemcached
  layout false
    
  def index
    @s = Session.current
    # These IDs come straight from id=#savedproducts on the client side (comma-separated)
    @products = params[:id].split(",").map{|id| Product.cached(id)}
    # Calculate best value for each feature, to display as bold
    @bestvalue = calculateBestValues

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
    end
  end 

private

  def calculateBestValues()
    
    bestvalue = {}
    if @products.length > 1
      contspecs = {}
      @products.each {|p| contspecs[p.id] = ContSpec.cache_all(p.id)}
      @s.continuous["filter"].each do |feature|
        # For every feature in ContinuousFeatures
        # For every product in @products
        # Find the min value and assign @bestvalue[feature]=product-id
        bestval = @products.map{|p|contspecs[p.id][feature]*@s.prefDirection[feature]}.max
        bestvalue[feature] = @products.select{|p|contspecs[p.id][feature]*@s.prefDirection[feature] == bestval}.map(&:id).join(",")
      end
    end
    bestvalue
  end
  
end