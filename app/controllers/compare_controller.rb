class CompareController < ApplicationController
# Compares products selected for comparison ('saved' products)
  
  layout 'optemo'
  # GET /saveds
  # GET /saveds.xml
  
  def decideWhichFeaturesToDisplay
    # To calculate which interesting features are to be displayed: 
    # Do not display those that are Unknown for all saved printers
    countVar = 0
    session[:productType].constantize::InterestingFeatures.each do |column|	    
  		for i in 0..@products.count-1
  			if !@products[i].send(column).nil?
  				@interestingFeatureDisplayed[countVar] = true
  			end
  		end
  		countVar = countVar + 1
    end
  end
  
  def index
    @products = []
    @displayString = "String"
    # To track whether an interesting feature is displayed or not-
    @interestingFeatureDisplayed = Array.new(session[:productType].constantize::InterestingFeatures.count, false)
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
    @saveds = []
    params[:path_info].collect do |id|
      @saveds << session[:productType].constantize.find(id)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
    end
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
    when 'itemwidth', 'itemlength', 'itemheight', 'itemweight': 
    	return displayString[0..3].capitalize + ' ' + displayString[4..-1] 
    when "packagewidth", "packagelength", "packageheight", "packageweight":
    	return  displayString[0..6].capitalize + ' ' + displayString[7..-1] 
    else 
      return displayString.capitalize 
    end
end

