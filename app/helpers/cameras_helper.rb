module CamerasHelper
  def nav_link
    s = Session.find(session[:user_id]).last_search
    if !s.nil?
      link_to 'Go back<br> to navigation', '/cameras/list/'+s 
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
      if @search.filter
        ""#link_to "See<br> more", {:id => @cameras[i], :action => 'sim', :controller => 'search', :f => 1}
      else
        ""#link_to "See<br> more", {:id => @cameras[i], :action => 'sim', :controller => 'search'}
      end
    else
      #Clustering present
      a = @desc[i].select{|ii|ii[0]=='cluster_count'}
      count = a[0][1] if !a.nil? && !a[0].nil?
      @desc[i].each_index do |ii|
        item = @desc[i][ii]
        if item[1] == 0 || item[0] == 'cluster_count'
  		    @desc[i][ii] = nil
  		  else
  		    @desc[i][ii][1] = item[1]>0 ? 'high' : 'low'
  		  end
  		end
  		@desc[i].compact!.each{|a|a.reverse!}
      if @search.filter
        link_to "Explore #{count} Similar Camera#{"s" if count > 1}", {:id => @cameras[i], :action => 'sim', :controller => 'search', :c => @clusters[i], :f => 1}, :title => "These cameras have " + combine_list(@desc[i])
      else
        link_to "Explore #{count} Similar Camera#{"s" if count > 1}", {:id => @cameras[i], :action => 'sim', :controller => 'search', :c => @clusters[i]}, :title => "These cameras have " + combine_list(@desc[i])
      end
    end
  end
  def combine_list(a)
    case a.length
    when 0: "similar properties to the given camera."
    when 1: a[0].join(' ')+'.'
    else
      ret = "and #{a.pop.join(' ')}."
      a.each {|i| ret = i.join(' ') + ', ' + ret }
      ret
    end
  end
end
