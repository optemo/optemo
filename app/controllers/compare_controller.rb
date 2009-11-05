class CompareController < ApplicationController
# Compares products selected for comparison ('saved' products)
  
  layout false
  # GET /saveds
  # GET /saveds.xml
    
  def index

    @session = @@session
    @products = []
    @bestvalue = {}
    @saveds = Saved.find_all_by_session_id(session[:user_id])
    @saveds.collect do |saved|
      prod = $model.find(saved.product_id)
      @products << prod
    end
    # Calculate best value for each feature, to display as bold
    CalculateBestValues()

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
    end
  end 

private

  def CalculateBestValues()
    # For every feature in ContinuousFeatures
      # For every product in @products
        # Find the min value and assign @bestvalue[feature]=product-id
    return if @products.length == 1
    $model::ContinuousFeatures.each do |feature|
      bestval = @products[0].send(feature)
      @bestvalue[feature] = @products[0].id
      @products.each do |product|
        if !product.send(feature).nil?
          if product.send(feature)*$PrefDirection[feature] > bestval*$PrefDirection[feature]
            @bestvalue[feature] = product.id
            bestval = product.send(feature)
          elsif product.send(feature)*$PrefDirection[feature] == bestval*$PrefDirection[feature] && product!=@products[0]
            @bestvalue[feature] = @bestvalue[feature].to_s + "," + product.id.to_s;
          end
        end
      end
    end
  end
  
end