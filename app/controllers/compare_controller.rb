class CompareController < ApplicationController
# Compares products selected for comparison ('saved' products)
  
  layout 'optemo'
  # GET /saveds
  # GET /saveds.xml
    
  def index
    @session = @@session
    # Following line is temporarily placed here. This will go where user preference values are calculated/updated
    PreferenceRelation.deleteBinaryRelations(@session.id)      # Lose the Binary Relations between products for previous user      
    
    @products = []
    @utility = []
    @displayString = ""
    # Link to latest product navigation page
    @navigationUrl = "/" + $model.urlname + "/compare/" + Search.find_by_session_id(session[:user_id], :order => 'updated_at DESC').to_s
    # To track whether an interesting feature is displayed or not-
    @interestingFeatureDisplayed = {} 
    @featureCssClass = {}
    @alreadySaved = {}
    @saveds = Saved.find_all_by_session_id(session[:user_id])
    @saveds.collect do |saved|
      prod = $model.find(saved.product_id)
      @products << prod
      @alreadySaved[prod.id] = true
    end

    # If no product ids are passed in query string then build @products from saved products    
    if !params[:id].nil?
      @products = []
      # Build @products from ids passed in query string
      sQuery = params[:id];
      idArray = sv_to_array(sQuery, '-')
      idArray.each{|pid| @products << $model.find(pid)}
    end

    if @products.empty?
      redirect_to @navigationUrl
    else
      # Reorder the product columns based on product utility
      ReorderProducts()      
      # After @products has been re-ordered, create the @search object
      cluster_ids = @products.map{|p| $nodemodel.find_by_product_id_and_region(p.id, $region, :order => 'id DESC').cluster_id.to_s}
      @search = Search.createFromPath(cluster_ids, @session.id)
     # @clusterDescs = @search.clusterDescription
      # Populate @interestingFeatureDisplayed variable
      decideWhichFeaturesToDisplay
      # Reorder the feature rows based on feature utility
      ReorderFeatures()
      
      @bestvalue = {}
      CalculateBestValues()
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
  
  def better
    original = params[:original]
    feature = $model.SFtoCFdictionary(params[:feature])
    current_version = $clustermodel.last.version
    nodes = $nodemodel.find_all_by_product_id_and_version(original, current_version).compact
    # Find all clusters that this product exists in, for the current version of clustering 
    cluster_ids = nodes.map{|n|n.cluster_id}
    if cluster_ids.length == 0
      flash[:error] = "There were no better/similar products found"
      redirect_to request.referer      
    else
      # Sort these clusters. The last cluster (with the largest cluster_id contains only that product)
      # All other clusters contain more products. Proceed up the hierarchy (decreasing cluster_id) to find a better product
      clusters = cluster_ids.sort.uniq[0..8].reverse
      clusters.each do |cluster|
        clusternodes = $nodemodel.find_all_by_cluster_id(cluster)   # ToDo: Add region constraint?
        productids = clusternodes.map{|n|n.product_id}
        thisproduct = $nodemodel.find_by_cluster_id_and_product_id(cluster, original)
        # Initialize original product id as the best product id for this cluster
        bestproduct = thisproduct
        productids.each do |pid|
            # If it is a better product, then redirect
            thatproduct = $nodemodel.find_by_cluster_id_and_product_id(cluster, pid)
            if isBetter(bestproduct, thatproduct, feature) && thatproduct!=thisproduct
              bestproduct = thatproduct
            end
        end
        if bestproduct.product_id.to_s != original
          render :text => bestproduct.product_id.to_s
          return
        end        
      end
      # No better product was found, return a product id of -1
      render :text => "-1"
      return
    end
  end
end

def isBetter(thisproduct, thatproduct, feature)
  # If value of feature is better, and price is lower then return true
  if $PrefDirection[feature]*thatproduct.send(feature) >= $PrefDirection[feature]*thisproduct.send(feature) && thatproduct.price <= thisproduct.price
    return true
  else
    return false
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
    when "itemdimensions"
      return "itemwidth"
    else 
      return f 
    end
end

def finalDisplay(product, column)
  case column
#    when 'brand'
#      return product.display(column) + ' ' + product.display('model') 
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
          # return "&#10003;" # This is not IE6 compatible
          # To make it IE compatible, replace by-
          image_tag '/images/checkmark.png', :width => 18, :height => 18
          # But then need to do something to fade out image when row is faded
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
  @products, @utility = SortArray(@products, @utility)
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
  if @products.count == 1
    return false
  end
  for i in 0..@products.count-1
    for j in 0..@products.count-1
      if i > j # So that a feature value gets compared with every other, exactly once
        if notSimilarFeatures(f, @products[i], @products[j])
          return false
        end
      end
    end
  end
  return true
end

def notSimilarFeatures(f, p1, p2)
# Definition of similarity, for different features can be provided here
# f iterates over PreferredDisplayFeatures
  case f
    when "scanner", "printserver", "colorprinter"
      f1 = finalDisplay(p1, f)
      f2 = finalDisplay(p2, f)
      if (f1 == f2)
        return false
      end
    when "itemdimensions", "packagedimensions"
      # If any dimension is Unknown, then keep the row faded. However, if there is any pair of products with  a difference
      # greater than the margin, then the row must be highlighted 
      if f=="itemdimensions"
        return false if (l1=p1.send("itemlength")).nil? || (w1=p1.send("itemwidth")).nil? || (h1=p1.send("itemheight")).nil? ||
            (l2=p2.send("itemlength")).nil? || (w2=p2.send("itemwidth")).nil? || (h2=p2.send("itemheight")).nil?
      elsif f=="packagedimensions"
        return false if (l1=p1.send("packagelength")).nil? || (w1=p1.send("packagewidth")).nil? || (h1=p1.send("packageheight")).nil? ||
            (l2=p2.send("packagelength")).nil? || (w2=p2.send("packagewidth")).nil? || (h2=p2.send("packageheight")).nil?
      end
      f1 = l1 * w1 * h1
      f2 = l2 * w2 * h2
      smaller = f1 <= f2 ? f1 : f2
      if (f1-f2).abs*100/smaller.to_f >= $margin
        return true
      end
    when "resolution"
      return true
    when "connectivity", "platform"
      # These are CSV strings
      f1 = p1.send(f)
      f2 = p2.send(f)
      if (f1 != f2)
        return true
      end
    when "price", "ppm", "paperinput" #, "ppmcolor", "itemweight", "packageweight", "paperoutput"
    # If the difference in the value of feature is greater than margin% of the smaller value, then the difference is significant
      f1 = p1.send(f)
      f2 = p2.send(f)
      smaller = f1 <= f2 ? f1 : f2
      if (f1-f2).abs*100/smaller.to_f >= $margin
        return true
      end
    else
      return true
    end    
end

def SortArray(toSort, basedOn)
  sortedArray = []
  finalBasedOn = []
  tempBasedOn = []

  maxBasedOn = 0.0    
  index = 0           
  counter = 0

  tempBasedOn = basedOn.dup

  while counter < toSort.count
    maxBasedOn = 0.0
    index = 0
    
    for i in 0..toSort.count-1       # Find Max Utility
      if(tempBasedOn[i] > maxBasedOn)
        maxBasedOn = tempBasedOn[i]
        index = i
      end
    end
    sortedArray[counter] = toSort[index]
    finalBasedOn[counter] = basedOn[index]
    counter = counter + 1
    tempBasedOn[index] = -1.0
  end  
  return sortedArray, finalBasedOn
end

def numberOfStars(utility)
 return ((utility*10).ceil)*0.5
 #  This formula is equivalent to:
 #    case utility
 #     	when 0..0.1:
 #     	  return 0.5
 #     	when 0.1..0.2
 #     	  return 1
 #     	when 0.2..0.3
 #     	  return 1.5
 #     	when 0.3..0.4:
 #     	  return 2
 #     	when 0.4..0.5:
 #     	  return 2.5
 #     	when 0.5..0.6:
 #     	  return 3
 #     	when 0.6..0.7:
 #     	  return 3.5
 #     	when 0.7..0.8:
 #         return 4
 #     	when 0.8..0.9:
 #     	  return 4.5
 #     	when 0.9..1:
 #     	  return 5
 #     end	
end

def contSpecialFeaturesDictionary(feature)
  if feature.index(' ').nil?
    spacePos = feature.length
  else 
    spacePos = feature.index(' ')
  end    
  firstWord = feature[0..spacePos-1]
  return firstWord + "est" + feature[spacePos..-1]
end

def displayComparisonFeature(i)
  returnString = ""
  DbFeature.find_all_by_product_type_and_feature_type_and_region(@session.product_type, 'Continuous',$region).each do |f|
    f_pref = @session.features.send(f.name+"_pref") 
    # Only if the user preferences indicate that this feature is important to the user
    if f_pref > $SignificantFeatureThreshold
      valThisProduct = @products[i].send(f.name)
      # Preference Direction can be used to display only good qualities (min or max)
      if $PrefDirection[f.name] == -1 
        if valThisProduct == @search.minimum(f.name)
          returnString = returnString + "- " + contSpecialFeaturesDictionary(session[:productType].constantize::ContinuousFeaturesDescLow[f.name]) + "<br>"
        end      
      else
        if valThisProduct == @search.maximum(f.name)
          returnString = returnString + "- " + contSpecialFeaturesDictionary(session[:productType].constantize::ContinuousFeaturesDescHigh[f.name]) + "<br>"
        end
      end  
    end
  end
 return returnString
end

# Separated value string to array converter. Separated value could be for example, '-'
def sv_to_array(svString, separator)
  oArray = []
  last = svString.index(separator)
  while last != nil
    item = svString[0..last]
    item = item.chop
    oArray<<item
    svString = svString[last+1..-1]
    last = svString.index(separator)
  end
  oArray<<svString
  oArray
end

private

# Returns a row of the factor table
def LookupFactorRow (pType, productId)
  return Factor.find(:first, :conditions => ['product_id = ? and product_type = ?', productId, pType])
end

# Calculates the Utility of a product, based on user-preferences
# Computation:
# For every Product,
# => 2 Database lookups      (Can be reduced to 1)
# => |Continuous Features| * 2 Arithmetic operations
def CalculateUtility(p)  
  cost = 0.0
  #getFactorRow = LookupFactorRow(session[:productType], product.id)
      getFactorRow = LookupFactorRow($model.name, p.send('id'))                    # TODO:
  userSession = Session.find(:first, :conditions => ['id = ?', session[:user_id]])
  # For all features
    session[:productType].constantize::ContinuousFeatures.each do |f|
    # Multiply factor value by the User's preference for that feature (weight) and add to cost
      cost = cost + getFactorRow.send(f) * userSession.features.send("#{f}_pref")
    end      
  return cost
end

def CalculateBestValues()
  # For every feature in ContinuousFeatures
    # For every product in @products
      # Find the min value and assign @bestvalue[feature]=product-id
  $model::ContinuousFeatures.each do |feature|
    bestval = @products[0].send(feature)
    @bestvalue[feature] = @products[0].id
    @products.each do |product|
      if product.send(feature)*$PrefDirection[feature] > bestval*$PrefDirection[feature]
        @bestvalue[feature] = product.id
        bestval = product.send(feature)
      elsif product.send(feature)*$PrefDirection[feature] == bestval && product!=@products[0]
        @bestvalue[feature] = @bestvalue[feature].to_s + "," + product.id.to_s;
      end
    end
  end
end

def IsPresentInCSV(item, csvString)
  # Parse csv string into array
  # match item with each element of array, and return true if match occurs
  values = csvString.to_s.split(',')
  return true if !values.index(item.to_s).nil?
  return false
end