module CompareHelper
  def landing?
    ! (request.referer && request.referer.match(/http:\/\/(laserprinterhub|localhost)/))
  end
  
  def sim_link(cluster,i, itemId)
    unless cluster.children.nil? || cluster.children.empty? || (cluster.size==1)
      "<div class='sim rounded'>" +
        link_to("#{cluster.size-1} More Product#{"s" if cluster.size > 2} In This Group", 
        "/compare/compare/"+cluster.children.map{|c|c.id}.join('-'), 
        :id => "sim#{i}", :class => 'simlinks', :name => itemId) +
      "</div>"
    else
      ""
    end
  end
  
  def overallmin(feat)
    ((ContSpec.allMinMax(feat)[0] || 0)*10).to_i.to_f/10
  end
  
  def overallmax(feat)
    ((ContSpec.allMinMax(feat)[1] || 0)*10).ceil.to_f/10
  end
  
  def isnil(a)
    if a.nil?
      yield
    else
      a
    end
  end
  
  def nav_link
    if request.env['HTTP_REFERER'] && request.env['HTTP_REFERER'].match('laserprinterhub|localhost')
      link_to 'Go back<br> to navigation', 'javascript:history.back()'
    else
      link_to 'Browse more products', :controller => 'products'
    end
  end
  
  def navtitle
    if Session.current.keyword.nil?
		  ["Browsing", Session.current.search.result_count, (Session.current.search.result_count > 1) ? t("#{$product_type}.title-plural") : t("#{$product_type}.title-plural")].join(" ")
		else
      "#{t("products.compare.search")}: '#{Session.current.keyword}', #{(Session.current.search.result_count > 1) ? t("products.compare.browsings",:count => Session.current.search.result_count) : t("products.compare.browsing")}" 
    end
  end
  
  def groupDesc(group, i)
    if $RelativeDescriptions
      if $LineItemView
        Session.current.search.boostexterClusterDescriptions[i].map{|d|t("products."+d, :default => d)}.map{|d|"<div style='position: relative;'>" + link_to(d, "#", :class => "description") + render(:partial => 'desc', :locals => {:feat => d}) + "</div>"}.join(" ")
      else
        Session.current.search.relativeDescriptions[i].map{|d|t("products."+d)}.join(", ")
      end
    else
      disptranslation = []
      dispString = ""
	    Session.current.search.boostexterClusterDescription(i).compact.flatten.uniq.each do |property|
	      disptranslation << t('products.' + property)
	    end
	    if group
	      if disptranslation.size>2
	        dispString = disptranslation[0..disptranslation.size-2].join(', ') + " "+t('products.' + "and") +" "+disptranslation[-1]
	      elsif disptranslation.size==2
	        dispString = disptranslation[0] + " "+ t('products.' + "and") + " "+ disptranslation[-1]
	      elsif disptranslation.size==1
	        dispString = disptranslation[0]
	      else
	        t('products.'+"Average")  
	      end
      else
	     if disptranslation.size>2
	       dispString = disptranslation[0]+ " "+ t('products.' + "and") +" "+disptranslation[1]
	     elsif disptranslation.size==2
	       dispString= disptranslation[0] + " "+t('products.' + "and") + " "+disptranslation[-1] 
	     elsif disptranslation.size==1
	       dispString=disptranslation[0]
	     else
	      t('products.'+"Average")  
	     end 
	    end      
	    dispString
	  end
 end
 
  def chosencats(feat)
    Session.current.search.userdatacats.select{|d|d.name == feat}.map(&:value)
  end
  
  def featuretext(search,cluster)
    out = []
    $Categorical["desc"].each do |feat|
      out << t("products.#{feat}") if cluster.representative.send(feat.intern)
    end
    $Continuous["desc"].each do |feat|
      feature = cluster.representative.send(feat.intern).to_i
		  out << "#{feature} #{t("products.#{feat}text")}"
	  end
	  $Binary["desc"].each do |feat|
      out << t("products.#{feat}") if cluster.representative.send(feat.intern)
    end
		out.join(" / ")
  end

  def imgurl(product)
    case $product_type
      when "flooring_builddirect" then "http://www.builddirect.com" + CGI.unescapeHTML(product.imgmurl.to_s)
      when "laptop_walmart" then CGI.unescapeHTML(product.imgmurl.to_s)
      else $product_type.split("_").first + "s/" + product.id.to_s + "_m.jpg"
    end
  end

end
