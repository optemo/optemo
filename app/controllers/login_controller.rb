class LoginController < ApplicationController
  def do_login
    # Retrieve the user's facebook user id
    # If a row for this fbid already exists in the sessions table, then set the session-id to point to this row and ignore/delete the current row  (for now)
    # If no such row exists, append the user's fbid to the session row that is currently being used
    # Configuration: Application Key provided by Facebook
    appKey = "7aeec628ded26fb3b03829fb4142da01"
    fbid = cookies[appKey +"_user"]   
    findSession = Session.where(:user => fbid).first;
    if findSession.nil?
      # User logged in for first time
      if session[:user_id].nil?
        redirect_to request.referer
      end
      currentSession = Session.find(session[:user_id]);
      currentSession.user = fbid
      currentSession.save
    else
      # User has logged in previously
      # Session.delete(session[:user_id]);    # Can discard this row
      session[:user_id] = findSession.id;
    end
   redirect_to params[:currpage]
  end
  
  def do_logout
    session[:user_id] = nil;
    redirect_to "/"
  end
end
