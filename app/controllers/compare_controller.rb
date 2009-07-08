class CompareController < ApplicationController
# Compares products selected for comparison ('saved' products)
  
  layout 'optemo'
  # GET /saveds
  # GET /saveds.xml
    
  def index
    @session = Session.find(session[:user_id])  # @session is required to retrieve preferences    
    @products = []
    @utility = []
    @displayString = ""
    # Link to latest product navigation page
    @navigationUrl = "/printers/list/" + Search.find_all_by_session_id(session[:user_id], :order => 'updated_at DESC').first.to_s
    # To track whether an interesting feature is displayed or not-
    @interestingFeatureDisplayed = {} 
    @featureCssClass = {}
    @saveds = Saved.find_all_by_session_id(session[:user_id])
    @dbfeat = {}
    DbFeature.find_all_by_product_type(session[:productType]).each {|f| @dbfeat[f.name] = f}
    @saveds.collect do |saved|
      @products << session[:productType].constantize.find(saved.product_id)
    end
    if @products.empty?
      redirect_to @navigationUrl
      return
    end
    # Reorder the product columns based on product utility
    ReorderProducts()      
    # Populate @interestingFeatureDisplayed variable
    decideWhichFeaturesToDisplay
    # Reorder the feature rows based on feature utility
    ReorderFeatures()
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
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
  session[:productType].constantize::DisplayedFeatures.each do |column|	    
		for i in 0..@products.count-1
			if canShowFeature?(column, i)
				@interestingFeatureDisplayed[column] = true   # If once set, the feature dispaly will be true for all products
			end
			# @featureCssClass[column] = "lowlightfeature"
			# @featureCssClass[column] = "regularfeature"
		end
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
end

def DispContFeatureDictionary(f)
  case f
    when "resolution"
      return "resolutionmax"
    when "ppmcolor"
      return "ppm"
    else 
      return f 
    end
end

def finalDisplay(product, column)
  case column
    when 'brand'
      return product.display(column) + ' ' + product.display('model') 
    when 'itemdimensions'
      return product.display('itemlength') + " x " + product.display('itemwidth') + " x " + product.display('itemheight') 
    when 'packagedimensions'
    	return product.display('packagelength') + " x " + product.display('packagewidth') + " x " + product.display('packageheight')
    when 'price'
      return product.display('pricestr')
    else
      case product.display(column)
        # Display Unavailable instead of Unknown
        when 'Unknown' 
    	    return "Unavailable"
        when "true"
          return image_tag '/images/checkmark.png', :width => 18, :height => 18
        when "false"
    	    return "x"		
        else
          return product.display(column)[0..20]
        end
    end
end

def ReorderProducts
  # To sort: @products
  # Based on: @utility
  for i in 0..@products.count-1
    @utility[i] = CalculateUtility(@products[i])
  end
  @toSort = @products.dup
  @basedOn = @utility.dup
  SortArray()
  @products = @sortedArray
  @utility = @finalBasedOn
end
  
def ReorderFeatures
  # To sort: InterestingFeatures
  # Based on: userPreferences for ContinuousFeatures
  
  prefHash = {}
  session[:productType].constantize::DisplayedFeatures.each do |f|
    correspondingf = DispContFeatureDictionary(f)
    if session[:productType].constantize::ContinuousFeatures.index(correspondingf) == nil
      prefHash[f] = 0
    else
      prefHash[f] = @session.features.send((correspondingf + "_pref").intern)
    end
  end
  # Reorder features in DisplayedFeatures into @preferredDisplayFeatures 
  @preferredDisplayFeatures = prefHash.sort{|a,b| a[1]<=>b[1]}.reverse  
end

def sameFeatureValue(f)
  for i in 0..@products.count-2
    # if finalDisplay(@products[i], f) != finalDisplay(@products[i+1], f)
    if notSimilarFeatures(f, finalDisplay(@products[i], f), finalDisplay(@products[i+1], f))
      return false
    end
  end
  return true
end

def notSimilarFeatures(f, f1, f2)
# Definition of similarity, for different features can be provided here
debugger
  case f
    when "scanner" || "printserver" || "colorprinter"
      if (f1 == f2)
        return false
      end
    when "ppm" || "papersize" || "itemweight" || "paperoutput" || "packageweight" # f in continuous features???
      margin = @dbfeat[f].max - @dbfeat[f].min
      margin = margin/10
      if (f1.to_f - f2.to_f).abs <= margin 
        return false
      end
      return true
    else
      return true
    end
end

def SortArray
  @sortedArray = []
  @finalBasedOn = []
  tempBasedOn = []

  maxBasedOn = 0.0    
  index = 0           
  counter = 0

  tempBasedOn = @basedOn.dup

  while counter < @toSort.count
    maxBasedOn = 0.0
    index = 0
    
    for i in 0..@toSort.count-1       # Find Max Utility
      if(tempBasedOn[i] > maxBasedOn)
        maxBasedOn = tempBasedOn[i]
        index = i
      end
    end
    @sortedArray[counter] = @toSort[index]
    @finalBasedOn[counter] = @basedOn[index]
    counter = counter + 1
    tempBasedOn[index] = -1.0
  end  
end