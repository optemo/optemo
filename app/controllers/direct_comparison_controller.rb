class DirectComparisonController < ApplicationController
# Compares products selected for comparison ('saved' products)
  include CachingMemcached
  layout false
    
  def index
    # These IDs come straight from id=#opt_savedproducts on the client side (comma-separated)
    @products = params[:id].split(",").map{|id| Product.cached(id)}
    # Calculate best value for each feature, to display as bold
    # We need to create a search in order for getFilters to work. This seems like a bit of a hack but I'm not totally
    # sure how the filter splitting code works. There is code left over that uses @s.continuous["filter"]
    # even though it seems deprecated. Ask Ray -ZAT
    Session.set_features([])
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
      Session.features["show"].each do |feature|
        # For every feature in ContinuousFeatures
        # For every product in @products
        # Find the min value and assign @bestvalue[feature]=product-id
        bestval = -1000000000
        bestproducts = []
        @products.each do |p|
          next if contspecs[p.id][feature.name].nil?
          featval = contspecs[p.id][feature.name]*(feature.value < 0 ? -1 : 1)
          if featval > bestval
            bestproducts = [p.id]
            bestval = featval
          elsif featval == bestval
            bestproducts << p.id
          end
        end
        bestvalue[feature.name] = bestproducts
      end
    end
    bestvalue
  end
  
end
