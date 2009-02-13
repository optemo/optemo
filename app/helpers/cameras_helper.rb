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
		text.join(', ')
  end
  def sim_link(i)
    if @desc[i].nil?
      #No cluster info
      link_to "See<br> more", {:id => @cameras[i], :action => 'sim', :controller => 'search', :pos => i, :camera => true}, :class => 'sim'
    else
      #Clustering present
      link_to "See more (#{+@desc[i].count})", {:id => @clusters[i], :action => 'sim', :controller => 'search', :pos => i}, :class => 'sim'
    end
  end
end
