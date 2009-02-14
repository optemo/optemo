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
    if @desc[i].nil? || @clusters.nil?
      #No cluster info
      link_to "See<br> more", {:id => @cameras[i], :action => 'sim', :controller => 'search'}, :class => 'sim'
    else
      #Clustering present
      a = @desc[i].select{|ii|ii[0]=='cluster_count'}
      count = a[0][1] if !a.nil? && !a[0].nil?
      link_to "See more (#{count})", {:id => @cameras[i], :action => 'sim', :controller => 'search', :c => @clusters[i]}, :class => 'sim'
    end
  end
end
