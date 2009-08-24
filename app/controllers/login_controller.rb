class LoginController < ApplicationController
  def do_login
    # Retrieve the user's facebook user id
    # If a row for this fbid already exists in the sessions table, then set the session-id to point to this row and ignore/delete the current row  (for now)
    # If no such row exists, append the user's fbid to the session row that is currently being used
    fbid = cookies[$AppKey +"_user"]   
    findSession = Session.find(:first, :conditions => ['user = ?', fbid]);
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
   redirect_to request.referer
  end
  
  def do_logout
    session[:user_id] = nil;
    redirect_to "/"
  end
end
