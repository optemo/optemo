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
  
  def roundmin(n)
    (n*10).to_i.to_f/10
  end
  def roundmax(n)
    (n*10).ceil.to_f/10
  end
  
  def dbmin(i2f, feat)
    i2f ? DbFeature.featurecache(feat).min.to_i/100 :  roundmin(DbFeature.featurecache(feat).min)
  end
  
  def dbmax(i2f, feat)
    i2f ? (DbFeature.featurecache(feat).max.to_f/100).ceil : feat=='itemweight' ? roundmax(DbFeature.featurecache(feat).max).ceil : roundmax(DbFeature.featurecache(feat).max)
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
		  (Session.current.search.result_count > 1) ? t("products.compare.browsings",:count => Session.current.search.result_count) + $model.name + "s" : t("products.compare.browsing") + $model.name
		  ["Browsing", Session.current.search.result_count,$RelativeDescriptions ? "<b>"+Session.current.search.searchDescription.map{|d|t("products."+d)}.join(", ")+"</b>" : nil, ($model.name == 'Camera' ? ((Session.current.search.result_count > 1) ? "Cameras" : "Camera") : ((Session.current.search.result_count > 1) ? "Printers" : "Printer"))].join(" ")
		else
      "#{t("products.compare.search")}: '#{Session.current.keyword}', #{(Session.current.search.result_count > 1) ? t("products.compare.browsings",:count => Session.current.search.result_count) : t("products.compare.browsing")}" 
    end
  end
  
  def groupDesc(group, i)
    if $RelativeDescriptions
      Session.current.search.boostexterClusterDescriptions[i].map{|d|t("products."+d)}.join(", ")
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
 
  def catsforfeature(feat)
    chosen_brands = Session.current.features.brand.split('*')
    DbFeature.featurecache(feat).categories.split('*').reject {|b| chosen_brands.index(b)}
  end
  
  def featuretext(search,cluster)
    out = []
    $model::SingleDescFeatures.each do |feat|
      if $model::BinaryFeatures.include?(feat) 
			  out << t("products.#{feat}") if cluster.representative.send(feat.intern)
			elsif $model::CategoricalFeatures.include?(feat)
		    out << cluster.representative.send(feat.intern)
			else
			  if $model::ItoF.include?(feat)
			    feature = cluster.representative.send(feat.intern).to_f/100
			  else
			    feature = cluster.representative.send(feat.intern).to_i
			  end
			  out << "#{feature} #{t("products.#{feat}text")}"
			end
		end
		out.join(" / ")
  end

end
