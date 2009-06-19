class CompareController < ApplicationController
# Compares products selected for comparison ('saved' products)
  
  layout 'optemo'
  # GET /saveds
  # GET /saveds.xml
    
  def index
    @products = [] # Will keep product IDs of saved items
    @displayString = ""
    # To track whether an interesting feature is displayed or not-
    @interestingFeatureDisplayed = Array.new(session[:productType].constantize::DisplayedFeatures.count, false)
    if params[:path_info].blank?
      @saveds = Saved.find_all_by_session_id(session[:user_id])
      @saveds.collect do |saved|
        @products << saved.product_id
      end
      if @products.empty?
        redirect_to "/printers"
      else
        redirect_to "/compare/#{@products.join('/')}"
      end
    else
      params[:path_info].collect do |id|
        @products << session[:productType].constantize.find(id)
      end
      # Populate @interestingFeatureDisplayed variable first
      decideWhichFeaturesToDisplay
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @products }
      end
    end
  end
  
  def list
#    newPrefList = []
#    newPrefList = params[:comparisonTable]
#    eval('session[:productType].constantize::DisplayedFeatures = %w(ppm ppm)')
#    redirect_to('/compare/index')
    
#    session[:productType].constantize::DisplayedFeatures = %w(brand ppm ttp resolution)
#    eval('session[:productType].constantize::DisplayedFeatures =  newPrefList')
  
    #redirect_to('/compare')
=begin
    @saveds = []
    params[:path_info].collect do |id|
      @saveds << session[:productType].constantize.find(id)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
    end
=end
  end

  # GET /saveds/1
  # GET /saveds/1.xml
  def show
    @saved = Saved.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @saved }
    end
  end

  # GET /saveds/new
  # GET /saveds/new.xml
  def new
    @saved = Saved.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @saved }
    end
  end

  # GET /saveds/1/edit
  def edit
    @saved = Saved.find(params[:id])
  end

  # POST /saveds
  # POST /saveds.xml
  def create
    @saved = Saved.new(params[:saved])

    respond_to do |format|
      if @saved.save
        flash[:notice] = 'Saved was successfully created.'
        format.html { redirect_to(@saved) }
        format.xml  { render :xml => @saved, :status => :created, :location => @saved }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @saved.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /saveds/1
  # PUT /saveds/1.xml
  def update
    @saved = Saved.find(params[:id])

    respond_to do |format|
      if @saved.update_attributes(params[:saved])
        flash[:notice] = 'Saved was successfully updated.'
        format.html { redirect_to(@saved) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @saved.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /saveds/1
  # DELETE /saveds/1.xml
  def destroy
    @saved = Saved.find(params[:id])
    @saved.destroy

    respond_to do |format|
      format.html { redirect_to(saveds_url) }
      format.xml  { head :ok }
    end
  end
end

def decideWhichFeaturesToDisplay
  # To calculate which interesting features are to be displayed: 
  # Do not display those that are Unknown for all saved printers
  countVar = 0
  session[:productType].constantize::DisplayedFeatures.each do |column|	    
		for i in 0..@products.count-1
			if canShowFeature?(column, i)
				@interestingFeatureDisplayed[countVar] = true
			end
		end
		countVar = countVar + 1
  end
end

def canShowFeature?(column, i)
  if column == 'itemdimensions'
    if @products[i].send('itemlength') != nil && @products[i].send('itemwidth') != nil && @products[i].send('itemheight') != nil  
      return true
    end
  elsif column == 'packagedimensions'
    if @products[i].send('packagelength') != nil && @products[i].send('packagewidth') != nil && @products[i].send('packageheight') != nil
      return true
    end
  elsif @products[i].send(column).nil?
    return false
  else
    return true
  end
end

def featuresDictionary
  displayString = @displayString

  case displayString
    when 'brand':
      return "Model"
    when 'ppm': 
    	return "Pages Per Minute"
    when 'colorprinter':
    	return "Color Printer"
    when 'printserver':
    	return "Print Server"
    when 'paperinput': 
    	return "Paper Input"
    when 'ppmcolor': 
    	return "Pages Per Minute, Colored"
    when "itemdimensions":
      return "Item dimensions"
    when "itemweight":
      return "Item weight"
    when "packagedimensions":
      return "Package dimensions"
    when "packageweight"
      return "Package weight"
    else 
      return displayString.capitalize 
    end
=begin
    when 'itemwidth', 'itemlength', 'itemheight', 'itemweight': 
    	return displayString[0..3].capitalize + ' ' + displayString[4..-1] 
    when "packagewidth", "packagelength", "packageheight", "packageweight":
    	return  displayString[0..6].capitalize + ' ' + displayString[7..-1] 
=end
end


ContinuousFeatures = %w(ppm itemwidth paperinput resolutionarea price)

# Returns a row of the factor table
def LookupFactorRow (pType, productId)
  return Factor.find(:first, :conditions => ['product_id = ? and product_type = ?', productId, pType])
end

# Calculates the Utility of a product, based on user-preferences
def CalculateUtility(product)
  cost = 0.0
  #getFactorRow = LookupFactorRow(session[:productType], product.id)
      getFactorRow = LookupFactorRow('Printer', 7)                    : TODO:
  # For all features
  ContinuousFeatures.each do |f|
    # Multiply factor value by the User's preference for that feature (weight) and add to cost
    cost = cost + getFactorRow.send(f) * Session.find(:first, :conditions => ['id = ?', session[:user_id]]).send("#{f}_pref")
  end      
  return cost
end
