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
  
  # This function formats a number's display precision in a way that humans find more reasonable.
  # Specifically, it takes numbers like 8177.99 and turns them into 8200, or numbers like 4.974 into 4.97.
  # This code is ported from application.js (in setting up slider increments).
  def format_acceptable_increments(number, round_direction='down')
    # These acceptable increments can be tweaked as necessary. Multiples of 5 and 10 look cleanest; 20 looks OK but 2 and 0.2 look weird.
		acceptableincrements = [1000, 500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01]
		comparator = number / 100.0 # so that's 81.7799
    increment = acceptableincrements.delete_if{|i| (i * 1.1) < comparator}.last
    
    realvalue = (number / increment)
    if round_direction == 'up'
      realvalue = realvalue.ceil * increment
    else
      realvalue = realvalue.round * increment
    end		
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
		["Browsing", Session.current.search.result_count, (Session.current.search.result_count > 1) ? t("#{$product_type}.title-plural") : t("#{$product_type}.title-plural")].join(" ")
  end
  
  def groupDesc(group, i)
    if $RelativeDescriptions
      descs = Session.current.search.boostexterClusterDescriptions[i].map{|d|t("products."+d, :default => d)}
      if $LineItemView
        descs.map{|d|"<div style='position: relative;'>" + link_to(d, "#", :class => "description") + render(:partial => 'desc', :locals => {:feat => d}) + "</div>"}.join(" ")
      else
        descs.join(", ")
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

  def columntext(groupings)
    if $SimpleLayout
      if groupings.nil?
        ['', 'Product', 'Price']
      else
        ['Choose Group', 'Best Pick', 'Cheapest Pick']
      end
    else
      ['Browse Similar', 'Group Differences', 'Our pick for this group']
    end
  end

  def imgurl(product)
    case $product_type
      when "flooring_builddirect" then "http://www.builddirect.com" + CGI.unescapeHTML(product.imgmurl.to_s)
      else CGI.unescapeHTML(product.imgmurl.to_s) # No need for constructing image URLs manually, they are all in the database now
    end
  end

end
