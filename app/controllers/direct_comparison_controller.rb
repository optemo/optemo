class DirectComparisonController < ApplicationController
# Compares products selected for comparison ('saved' products)
  include CachingMemcached
  layout false
    
  def index
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
      $Continuous["filter"].each do |feature|
        # For every feature in ContinuousFeatures
        # For every product in @products
        # Find the min value and assign @bestvalue[feature]=product-id
        bestval = @products.map{|p|ContSpec.cache(p.id, feature).value*$PrefDirection[feature]}.max
        bestvalue[feature] = @products.select{|p|ContSpec.cache(p.id, feature).value*$PrefDirection[feature] == bestval}.map(&:id).join(",")
      end
    end
    bestvalue
  end
  
end