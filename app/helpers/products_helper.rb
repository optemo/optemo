module ProductsHelper
  def nav_link
    s = Session.find(session[:user_id])
    if !s.nil?
      link_to 'Go back<br> to navigation', '/products/list/'+s.URL
    else
      link_to 'Browse more products', :controller => 'products'
    end
  end
  def description(i)
    text = []
		session[:productType].constantize::MainFeatures.each do |f|
		  res = @dbprops.toPhrase(f,@products[i].send(f))
			text << res unless res.blank?
		end
		text.join(', ')
  end
  def sim_link(i)
    if @desc[i].nil? || @clusters.nil?
      #No cluster info
      ""
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
        "<div class='sim'>" +
          link_to("Explore #{count} Similar Product#{"s" if count > 1}", 
          {:id => @products[i], :action => 'sim', :controller => 'search', :c => @clusters[i], :f => session[:search_id]}, 
          :title => "These products have " + combine_list(@desc[i])) +
        "</div>"
      else
        "<div class='sim'>"+
          link_to("Explore #{count} Similar Product#{"s" if count > 1}",
          {:id => @products[i], :action => 'sim', :controller => 'search', :c => @clusters[i]},
          :title => "These products have " + combine_list(@desc[i])) + 
        "</div>"
      end
    end
  end
  def combine_list(a)
    case a.length
    when 0: "similar properties to the given product."
    when 1: a[0].join(' ')+'.'
    else
      ret = "and #{a.pop.join(' ')}."
      a.each {|i| ret = i.join(' ') + ', ' + ret }
      ret
    end
  end
end
