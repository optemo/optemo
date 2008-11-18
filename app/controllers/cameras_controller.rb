class CamerasController < ApplicationController
  #require 'rubygems'
  #require 'config/environment'
  #require 'scrubyt'

  require 'open-uri'
  # GET /cameras
  # GET /cameras.xml
  def index
    @cameras = Camera.valid.find(:all, :order => 'RAND()', :limit => 9)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cameras }
    end
  end

  # GET /cameras/1
  # GET /cameras/1.xml
  def show
    @camera = Camera.find(params[:id])

    respond_to do |format|
      format.html { render :layout => 'plain'}
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
  
  def scrape
    call_rake :amazon_categories
    flash[:notice] = "Scraping Amazon"
    redirect_to cameras_url
    
    #open(params[:funk][:file]) do |uri|
    #  @cameras = amazon.scrape(uri.read)
    #end
    #render :action => 'index'
  end
end
