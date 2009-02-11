module CamerasHelper
  def nav_link
    s = Session.find(session[:user_id]).last_search
    if !s.nil?
      link_to 'Go back to navigation', '/cameras/list/'+s 
    else
      link_to 'Browse more cameras', :controller => 'cameras'
    end
  end
  def description(i)
    text = []
		Camera::MainFeatures.each do |f|
		  res = @dbprops.toPhrase(f,@cameras[i].send(f))
			text << res unless res.blank?
		end
		text.join(',')
  end
end
