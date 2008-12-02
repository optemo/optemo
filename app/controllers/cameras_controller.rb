class CamerasController < ApplicationController
  #require 'rubygems'
  #require 'config/environment'
  #require 'scrubyt'
  layout 'optemo', :except => :show
  require 'open-uri'
  # GET /cameras
  # GET /cameras.xml
  def index
    @cameras = Camera.valid.find(:all, :order => 'RAND()', :limit => 9)
    redirect_to "/cameras/list/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/#{@cameras.pop.id}/"
  end
  
  def list
    @cameras = []
    num = "i0"
    9.times do
      @cameras << Camera.find(params[num.next!])
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cameras }
    end
  end

  # GET /cameras/1
  # GET /cameras/1.xml
  def show
    @camera = Camera.find(params[:id])
    
    #Session Tracking
    s = Viewed.new
    s.session_id = session[:user_id]
    s.camera_id = @camera.id
    s.save
    
    respond_to do |format|
      format.html 
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
  
  def sim
    #Session Tracking
    s = Similar.new
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    #Cleanse pos to be one digit
    params[:pos] = params[:pos].gsub(/[^0-8]/,'')[0,1]
    s.session_id = session[:user_id]
    s.camera_id = params[:id]
    s.save
    newids = %x["/optemo/site/lib/c_code/connect" "#{params[:id]}"]
    
    redirect_to "/cameras/list/#{newids.strip.split.insert(params[:pos].to_i,params[:id]).join('/')}"
  end
  
  def save
    #Session Tracking
    s = Saved.new
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    s.session_id = session[:user_id]
    s.camera_id = params[:id]
    s.save
    flash[:notice] = 'Saved has been saved.'
    redirect_to :action => 'index'
  end
end
