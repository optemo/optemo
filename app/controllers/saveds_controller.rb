class SavedsController < ApplicationController
  def create
    #Session Tracking

    @ajax = params[:ajax]   # Check whether Ajax call is made and accordingly decide whether to return div tag in html
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    # Error checking has already been done outside of here, so I'm pretty sure we don't need it anymore.
    # Just get the product data only, no more DB call
      @product = $model.find(params[:id])
      respond_to do |format|
        format.html
      end
  end
end
