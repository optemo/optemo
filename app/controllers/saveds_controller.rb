class SavedsController < ApplicationController
  def create
    #Session Tracking

    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    #If product hasn't been put in Saved by that user yet:
    if Saved.find_by_product_id_and_session_id(params[:id],session[:user_id]).nil?
      @product = $model.find(params[:id])
      s = Saved.new
      s.session_id = session[:user_id]
      s.product_id = params[:id]
      s.save
      respond_to do |format|
        format.html
      end
    else
      raise ArgumentError, "That product is already saved"
    end
  end

  def destroy
    Saved.find_by_session_id_and_product_id(session[:user_id], params[:id]).destroy
    render :nothing => true
  end

end
