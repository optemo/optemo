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
  
  def acceptableincrements(min, max)
    fudgefactor = 5.0 # Fudge factor; this determines how many increments are created.
    current = min
    increments = []
    while (current < max) do
      increments.push(current)
      increment = current / fudgefactor
      # Round based on some vague notion of "divide 250 by 10, but divide 500 by 100"
      base = Math.log10((current/fudgefactor).to_f).floor 
      current += increment
      current = (((current / (10**base).to_f).ceil) * (10**base).to_f)
    end
    increments.push(max)
    increments.map{|i|(i.round == i) ? i.to_i : i }
  end
  
  def nav_link
    if request.env['HTTP_REFERER'] && request.env['HTTP_REFERER'].match('laserprinterhub|localhost')
      link_to 'Go back<br> to navigation', 'javascript:history.back()'
    else
      link_to 'Browse more products', :controller => 'products'
    end
  end
  
  def navtitle
    s = Session.current
		[s.search.result_count, (s.search.result_count > 1) ? t("#{s.product_type}.title-plural") : t("#{s.product_type}.title-plural")].join(" ")
  end
  
  def groupDesc(group, i)
    s = Session.current
    if s.relativeDescriptions
      descs = s.search.boostexterClusterDescriptions[i].map{|d|t("products."+d, :default => d)}
      if s.directLayout
        descs.map{|d|"<div style='position: relative;'>" + link_to(d, "#", :class => "description") + render(:partial => 'desc', :locals => {:feat => d}) + "</div>"}.join(" ")
      else
        descs.join(", ")
      end
    else
      disptranslation = []
      dispString = ""
	    s.search.boostexterClusterDescription(i).compact.flatten.uniq.each do |property|
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
    s = Session.current
    out = []
    s.categorical["desc"].each do |feat|
      out << t("products.#{feat}") if cluster.representative.send(feat.intern)
    end
    s.continuous["desc"].each do |feat|
      feature = cluster.representative.send(feat.intern).to_i
		  out << "#{feature} #{t("products.#{feat}text")}"
	  end
	  s.binary["desc"].each do |feat|
      out << t("products.#{feat}") if cluster.representative.send(feat.intern)
    end
		out.join(" / ")
  end

  def columntext(groupings)
    if Session.current.directLayout
      if groupings.nil?
        ['', 'Product Details', 'Price']
      else
        ['Choose Group', 'Best Pick', 'Cheapest Pick']
      end
    else
      ['Browse Similar', 'Group Differences', 'Our pick for this group']
    end
  end

  def popuptext(number, text, nexttext="Next &gt;&gt;")
    "<div id='popupTour#{number}' class='popupTour'>
    	<a class='deleteX' href='#'><img src='/images/close.png' alt='Close'/></a>
    	<h1>Discovery Browser Tour</h1>
    	<p>#{text}
    		<br/><br/>
    		<a href='#' class='popupnextbutton'>#{nexttext}</a>
    		<br/><hr width='90%'/>
    		<span class='popupcloseinstructions'>Click X to close at any time</span>
    	</p>
    </div>"
  end

  def imgurl(product)
    case Session.current.product_type
      when "flooring_builddirect" then "http://www.builddirect.com" + CGI.unescapeHTML(product.imgmurl.to_s)
      else CGI.unescapeHTML(product.imgmurl.to_s) # No need for constructing image URLs manually, they are all in the database now
    end
  end

  def imgsurl(product)
    case Session.current.product_type
      when "flooring_builddirect" then "http://www.builddirect.com" + CGI.unescapeHTML(product.imgsurl.to_s)
      else CGI.unescapeHTML(product.imgsurl.to_s)
    end
  end

end
