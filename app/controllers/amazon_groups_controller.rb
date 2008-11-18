class AmazonGroupsController < ApplicationController
  # GET /amazon_groups
  # GET /amazon_groups.xml
  def index
    @amazon_groups = AmazonGroup.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @amazon_groups }
    end
  end

  # GET /amazon_groups/1
  # GET /amazon_groups/1.xml
  def show
    @amazon_group = AmazonGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @amazon_group }
    end
  end

  # GET /amazon_groups/new
  # GET /amazon_groups/new.xml
  def new
    @amazon_group = AmazonGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @amazon_group }
    end
  end

  # GET /amazon_groups/1/edit
  def edit
    @amazon_group = AmazonGroup.find(params[:id])
  end

  # POST /amazon_groups
  # POST /amazon_groups.xml
  def create
    @amazon_group = AmazonGroup.new(params[:amazon_group])

    respond_to do |format|
      if @amazon_group.save
        flash[:notice] = 'AmazonGroup was successfully created.'
        format.html { redirect_to(@amazon_group) }
        format.xml  { render :xml => @amazon_group, :status => :created, :location => @amazon_group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @amazon_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /amazon_groups/1
  # PUT /amazon_groups/1.xml
  def update
    @amazon_group = AmazonGroup.find(params[:id])

    respond_to do |format|
      if @amazon_group.update_attributes(params[:amazon_group])
        flash[:notice] = 'AmazonGroup was successfully updated.'
        format.html { redirect_to(@amazon_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @amazon_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /amazon_groups/1
  # DELETE /amazon_groups/1.xml
  def destroy
    @amazon_group = AmazonGroup.find(params[:id])
    @amazon_group.destroy

    respond_to do |format|
      format.html { redirect_to(amazon_groups_url) }
      format.xml  { head :ok }
    end
  end
end
