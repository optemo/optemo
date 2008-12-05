class SavedsController < ApplicationController
  def create
    #Session Tracking

    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    #debugger
    if Saved.find_by_camera_id_and_session_id(params[:id],session[:user_id]).nil?
      @camera = Camera.find(params[:id])
      s = Saved.new
      s.session_id = session[:user_id]
      s.camera_id = params[:id]
      s.save
      respond_to do |format|
        format.html
      end
    else
      raise ArgumentError, "That camera is already saved"
    end
  end

  def destroy
    Saved.find_by_session_id_and_camera_id(session[:user_id], params[:id]).destroy
  end

end
