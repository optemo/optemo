class CamerasController < ApplicationController
  #require 'rubygems'
  #require 'config/environment'
  #require 'scrubyt'
  layout 'optemo'
  require 'open-uri'
  # GET /cameras
  # GET /cameras.xml
  def index
    #@cameras = Camera.valid.find(:all, :order => 'RAND()', :limit => 9)
    #redirect_to "/cameras/list/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/"
  end
  
  def list
    @session = Session.find(session[:user_id])
    #Filtering variables
    @search = @session.search
    chosen = []
    chosen = YAML.load(@search.chosen) if @search.chosen
    @dbprops = DbProperty.find(:first)
    #Navigation Variables
    @cameras = []
    @desc = []
    "i1".upto("i9") do |num|
      @cameras << Camera.find(params[num])
      
      myc = chosen.find{|c| c[:id].to_s == params[num]}
      if myc.nil?
        #Otherwise fill in a null value
        @desc << nil
      else
        #Find the cluster's description
        myc.delete('id')
        @desc << myc.to_a
      end
    end
    @message = session[:message]
    #Saved Bar variables
    @picked_cameras = @session.saveds.map {|s| s.camera}
    
    
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cameras }
    end
  end

  # GET /cameras/1
  # GET /cameras/1.xml
  def show
    @plain = params[:plain].nil?? false : true
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    @camera = Camera.find(params[:id])
    #Session Tracking
    s = Viewed.new
    s.session_id = session[:user_id]
    s.camera_id = @camera.id
    s.save
    respond_to do |format|
      format.html { if @plain
                      render :layout => false
                    else
                      render :http => 'show' 
                    end }
      format.xml  { render :xml => @camera }
    end
  end

  # GET /cameras/new
  # GET /cameras/new.xml
  def new
    @camera = Camera.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @camera }
    end
  end

  # GET /cameras/1/edit
  def edit
    @camera = Camera.find(params[:id])
  end

  # POST /cameras
  # POST /cameras.xml
  def create
    @camera = Camera.new(params[:camera])

    respond_to do |format|
      if @camera.save
        flash[:notice] = 'Camera was successfully created.'
        format.html { redirect_to(@camera) }
        format.xml  { render :xml => @camera, :status => :created, :location => @camera }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @camera.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cameras/1
  # PUT /cameras/1.xml
  def update
    @camera = Camera.find(params[:id])

    respond_to do |format|
      if @camera.update_attributes(params[:camera])
        flash[:notice] = 'Camera was successfully updated.'
        format.html { redirect_to(@camera) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @camera.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cameras/1
  # DELETE /cameras/1.xml
  def destroy
    @camera = Camera.find(params[:id])
    @camera.destroy

    respond_to do |format|
      format.html { redirect_to(cameras_url) }
      format.xml  { head :ok }
    end
  end
  
  def destroy_all
    @cameras = Camera.find(:all)
    @cameras.each do |camera|
      camera.destroy
    end
    redirect_to cameras_url
  end
  
end
