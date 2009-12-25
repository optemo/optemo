module ProductsHelper
  def landing?
    ! (request.referer && request.referer.match(/http:\/\/(laserprinterhub|localhost)/))
  end
  
  def sim_link(cluster,i, itemId)
    unless cluster.children(@session).nil? || cluster.children(@session).empty? || (cluster.size(@session)==1)
      "<div class='sim rounded'>" +
        link_to("#{cluster.size(@session)-1} More Product#{"s" if cluster.size(@session) > 2} In This Group", 
        "/#{$model.urlname}/compare/"+cluster.children(@session).map{|c|c.id}.join('-'), 
        :id => "sim#{i}", :class => 'simlinks', :name => itemId) +
      "</div>"
    else
      ""
    end
  end
  
  def roundmin(n)
    (n*10).to_i.to_f/10
  end
  def roundmax(n)
    (n*10).ceil.to_f/10
  end
  
  def dbmin(i2f, feat)
    i2f ? $dbfeat[feat].min.to_i/100 :  roundmin($dbfeat[feat].min)
  end
  
  def dbmax(i2f, feat)
    i2f ? ($dbfeat[feat].max.to_f/100).ceil : feat=='itemweight' ? roundmax($dbfeat[feat].max).ceil : roundmax($dbfeat[feat].max)
  end
  
  def nav_link
    
    if request.env['HTTP_REFERER'] && request.env['HTTP_REFERER'].match('laserprinterhub|localhost')
      link_to 'Go back<br> to navigation', 'javascript:history.back()'
    else
      link_to 'Browse more products', :controller => 'products'
    end
    
  end
  
  def h1title
    if @allSearches.empty?
      if @session.searchterm.nil?
        $model.urlname.capitalize
      else
        "Search: '#{@session.searchterm}'"
      end
    else
      "#{@allSearches.last.desc} #{$model.urlname.capitalize}"
    end
  end
  
  def navtitle
    if @s.searchterm.nil?
		  (@s.result_count > 1) ? t("products.compare.browsings",:count => @s.result_count) + $model.name + "s" : t("products.compare.browsing") + $model.name
		  ["Browsing", @s.result_count,$RelativeDescriptions ? "<b>"+@s.searchDescription.map{|d|t("products."+d)}.join(", ")+"</b>" : nil, ($model.name == 'Camera' ? ((@s.result_count > 1) ? "Cameras" : "Camera") : ((@s.result_count > 1) ? "Printers" : "Printer"))].join(" ")
		else
      "#{t("products.compare.search")}: '#{@s.searchterm}', #{(@s.result_count > 1) ? t("products.compare.browsings",:count => @s.result_count) : t("products.compare.browsing")}" 
    end
  end
  
  def groupDesc(group, i)
    if $RelativeDescriptions
      @s.relativeDescriptions[i].map{|d|t("products."+d)}.join(", ")
    else
      disptranslation = []
      dispString = ""
	    @s.clusterDescription(i).compact.flatten.uniq.each do |property|
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
 
  def catsforfeature(session,feat)
    chosen_brands = @session.features.brand.split('*')
    $dbfeat[feat].categories.split('*').reject {|b| chosen_brands.index(b)}
  end

end
