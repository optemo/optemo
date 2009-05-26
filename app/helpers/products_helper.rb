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
		  res = @dbprops.toPhrase(f,@c.products[i].send(f))
			text << res unless res.blank?
		end
		text.join(', ')
  end
  
  def sim_link(i)
    #Clustering present
    return "" unless @c.desc
    a = @c.desc[i].select{|ii|ii[0]=='cluster_count'}
    count = a[0][1] if !a.nil? && !a[0].nil?
    @c.desc[i].each_index do |ii|
      item = @c.desc[i][ii]
      if item[1] == 0 || item[0] == 'cluster_count'
  	    @c.desc[i][ii] = nil
  	  else
  	    @c.desc[i][ii][1] = case item[1]
  	        when 1: 'low'
  	        when 2: 'avg'
  	        when 3: 'high'
  	    end
  	  end
  	end
  	@c.desc[i].compact!.each{|a|a.reverse!}
  	unless @c.subclusters[i].nil?
      "<div class='sim'>" +
        link_to("Explore #{count} Similar Product#{"s" if count > 1}", 
        "/#{!session[:productType].nil? ? session[:productType].pluralize.downcase : $DefaultProduct.pluralize.downcase}/list/"+@c.subclusters[i], 
        :title => "These products have " + combine_list(@c.desc[i]), :id => "sim#{i}") +
      "</div>"
    else
      ""
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
