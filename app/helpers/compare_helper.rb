module CompareHelper
  def landing?
    ! (request.referer && request.referer.match(/http:\/\/(laserprinterhub|localhost)/))
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
		comparator = number / 100.0 # so that's 81.7799 or 1.1999
    increment = acceptableincrements.delete_if{|i| i < comparator}.last
    realvalue = (number / increment) 
    if round_direction == 'up'
      realvalue = realvalue.ceil * increment
    else
      realvalue = realvalue.floor * increment
    end
    # Weird floating point bug here
    (realvalue * 100).to_i.to_f / 100.0
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
    increments.map{|i|(i.round == i) ? i.to_i : (i * 100.0).to_i.to_f / 100.0 }
  end
  
  def nav_link
    if request.env['HTTP_REFERER'] && request.env['HTTP_REFERER'].match('laserprinterhub|localhost')
      link_to 'Go back<br> to navigation', 'javascript:history.back()'
    else
      link_to 'Browse more products', :controller => 'products'
    end
  end
  
  def navtitle
    res = t("#{Session.product_type}.navtitle")
    if Session.search.products_size > 1
      res + t("#{Session.product_type}.navtitle2").pluralize
    else
        res + t("#{Session.product_type}.navtitle2")
    end    
  end
  
  def groupDesc(group, i)
    return "Description"
    s = Session
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
    Session.search.userdatacats.select{|d|d.name == feat}.map(&:value)
  end
  
  def featuretext(product_id)
    s = Session
    out = []
    s.categorical["desc"].each do |feat|
      out << CatSpec.cache_all(product_id)[feat]
    end
    s.continuous["desc"].each do |feat|
      #num = "%.1f" % ContSpec.cache_all(product_id)[feat]
      num = ContSpec.cache_all(product_id)[feat]
      num = "<1" if feat == "maxresolution" && num == "1"
      num = num.to_i if num.to_i==num
		  out << t('features.'+feat, :num =>  number_with_delimiter(num), :default =>  number_with_delimiter(num))
	  end
	  s.binary["desc"].each do |feat|
      out << BinSpec.cache_all(product_id)[feat]
    end
		out.join(", ")
  end

  def columntext(showgroups)
    if Session.directLayout
      if showgroups
        ['Choose Group', 'Best Pick', 'Cheapest Pick']
      else
        ['', 'Product Details', 'Price']
      end
    else
      ['Browse Similar', 'Group Differences', 'Our pick for this group']
    end
  end

  def popuptext(number, text, nexttext="Next &gt;&gt;")
    "<div id='popupTour#{number}' class='popupTour'>" + \
    link_to("X", "#", :class => 'deleteX') + \
    	"<h1>Optemo " + (Session.directLayout ? 'Direct' : 'Assist').html_safe + " Tour</h1>
    	<p>#{text}
    		<br/><br/>
    		<a href='#' class='popupnextbutton'>#{nexttext}</a>
    		<br/><hr width='90%'/>
    		<span class='popupcloseinstructions'>Click X to close at any time</span>
    	</p>
    </div>"
  end

  # This function should be deprecated with img urls coming from the cat_specs table now.
  def imgurl(product, size)
    case size
    when 'm'
      return "http://www.builddirect.com" + CGI.unescapeHTML(product.imgmurl.to_s) if Session.product_type == "flooring_builddirect"
    when 's'
      return "http://www.builddirect.com" + CGI.unescapeHTML(product.imgsurl.to_s) if Session.product_type == "flooring_builddirect"
    end
    CGI.unescapeHTML(CatSpec.cache_all(product.id)["img" + size + "url"].to_s) # No need for constructing image URLs manually, they are all in the database now
  end
  
  def withunit(number,feature)
    if feature == "price"
      t('products.' + feature+"unit")+number.to_s
    else
      [number,t('products.' + feature+"unit", :default => "")].reject(&:blank?).join(" ")
    end
  end
  
  def category_select(feat,expanded)
    select('superfluous', feat, [expanded ? t('products.add')+t(Session.product_type+'.specs.'+feat+'.name') : t('products.all')+t(Session.product_type+'.specs.'+feat+'.name').pluralize] + SearchProduct.cat_counts(feat,expanded,true).map{|k,v| ["#{k} (#{v})", k]}, options={}, {:id => feat+"selector", :class => "selectboxfilter"})
  end
  
  def special_main_boxes(type, num)
    res = ""
    res << '<div class="rowdiv">'
    open = true
    prods = @s.search.products_landing(type)
    for i in 0...num
      case type
      when "featured"
        if prods.size > 0    
          res << render(:partial => 'navbox', :locals => {:i => i, :product => Product.cached(prods[i].product_id)})
        end
      when "orders"
        if prods.size > 0
          res << render(:partial => 'navbox', :locals => {:i => i, :product => Product.cached(prods[i].product_id)})
        end
      when 'customerRating'
        if prods.size > 0
          res << render(:partial => 'navbox', :locals => {:i => i, :product => Product.cached(prods[i].product_id)})
        end
      end                
    end    
    res << '<div style="clear: both"></div></div>' if open && !@s.directLayout
  end
  
  
  def landing_main_boxes(type)
    res = ""
    num_examples = 3
    res << '<div class="rowdiv">'
    open = true
    prods = @s.search.products_landing
    for i in 0...num_examples
      case type
      when "featured"
        if prods[0].size > 0
          res << render(:partial => 'navbox', :locals => {:i => i, :product => Product.cached(prods[0][i].product_id)})
        end
      when "orders"
        if prods[1].size > 0
          res << render(:partial => 'navbox', :locals => {:i => i, :product => Product.cached(prods[1][i].product_id)})
        end
      when 'customerRating'
        if prods[2].size > 0
          res << render(:partial => 'navbox', :locals => {:i => i, :product => Product.cached(prods[2][i].product_id)})
        end
      end                
    end    
    res << '<div style="clear: both"></div></div>' if open && !@s.directLayout
  end
    
  def main_boxes
    res = ""
    if @s.directLayout # List View (Optemo Direct)
  		if @s.search.groupby.nil?
  			@products.each_index do |i|
  				res << render(:partial => 'singlelist', :locals => {:product => Product.cached(@products[i]), :i => i})
  			end
  		else
  			@s.search.groupings.each do |grouping|
  				res << render(:partial => 'grouping', :locals => {:grouping => grouping, :group => true})
  			end
  		end
  	else
  	  if @s.mobileView
  	    if @s.search.products_size != 0
          for i in 0...[@s.search.cluster.numclusters,@s.numGroups].min
            res << render(:partial => 'mobilebox', :locals => {:cluster => @s.search.cluster.children[i], :group => @s.search.cluster.children[i].size>1, :representative => @s.search.cluster.children[i].representative})
          end
        else
	        res << "<div style=\"padding:10px;\">No search results. Please search again or " + link_to("start over", "/") + ".</div>"
        end
	    else # Grid View (Optemo Assist)
    		for i in 0...@s.search.paginated_products.size
    		  if i % (Float(@s.numGroups)/3).ceil == 0
    			  res << '<div class="rowdiv">'
    			  open = true
    		  end
    		  #Navbox partial to draw boxes
    		  res << render(:partial => 'navbox', :locals => {:i => i, :product => @s.search.paginated_products[i]})
          if i % (Float(@s.numGroups)/3).ceil == (Float(@s.numGroups)/3).ceil - 1
            res << '<div style="clear: both"></div></div>'
            open = false
          end
    		end
  		end
  	end
  	res << '<div style="clear: both"></div></div>' if open && !@s.directLayout
  	res << '<span id="actioncount" style="display:none">' + "#{[Session.search.id.to_s].pack("m").chomp}</span>"
    res << "#{will_paginate(@s.search.paginated_products)}"
  	res
	end
   
	def adjustingfilters
	  #@s.search.userdataconts
	  new_filters = []
	    unless Session.search.userdataconts.empty?
         Session.search.userdataconts.each do |se| 
           if @s.search.extended.min(se.name)<se.min  
             new_filters << se.name + "_min=" + @s.search.extended.min(se.name).to_s
             new_filters << se.name + "_max=" + se.max.to_s
           end
           if @s.search.extended.max(se.name)>se.max 
             new_filters<<se.name + "_max=" + @s.search.extended.max(se.name).to_s
             new_filters<<se.name + "_min=" + se.min.to_s
           end   
         end
      end  
      unless Session.search.userdatacats.empty?
        curr_feats=Session.search.userdatacats.map{|se| se.name}.uniq
        curr_feats.each{|f| new_filters << (f + "") unless (@s.search.extended.cat_vals(f) - Session.search.userdatacats.map{|se| se.value if se.name==f}.compact).nil?}  
      end
      #unless Session.search.userdatabins.empty?
      #  curr_feats=Session.search.userdatabins.map{|se| se.name}.uniq
      #  curr_feats.each{|f| new_filters << (f + "") unless (@s.search.extended.bin_val(f)-Session.search.userdatabins.map{|se| se.value if se.name==f}.compact).nil?}
      #end   
    new_filters << "extended_hash=" + @s.search.extended.id.to_s
    new_filters = new_filters.compact
    new_filters.join("&")
	end  
	
	def adjustingfilters_hash
	  #@s.search.userdataconts
	  new_filters = {}
	    unless Session.search.userdataconts.empty?
         Session.search.userdataconts.each do |se| 
           if @s.search.extended.min(se.name)<se.min  
             new_filters["Minimum " + se.name] = @s.search.extended.min(se.name)
           end
           if @s.search.extended.max(se.name)>se.max 
             new_filters["Maximum " + se.name] =@s.search.extended.max(se.name)
           end   
         end
      end  
      unless Session.search.userdatacats.empty?
        curr_feats=Session.search.userdatacats.map{|se| se.name}.uniq
        curr_feats.each do |f|
            unless @s.search.extended.cat_vals(f).nil?
              new_vals = @s.search.extended.cat_vals(f) - Session.search.userdatacats.map{|se| se.value if se.name==f}.uniq  
              new_filters[f]= "All "+f+"s" unless new_vals.empty?
            end  
        end    
      end
    new_filters 
	end
	
	def getDist(feat)
    unless defined? @dist
      unless defined? $d
       $d = Distribution.new
      end
	    @dist = $d.computeDist
	  end  
	  @dist[feat]
  end
  
  def sortbyList
    sortbyList = [] # Session.search.sortby == "relevance" || Session.search.sortby.blank? ? t("products.relevance") : link_to(t("products.relevance"), "#", :'data-feat' => "relevance", :class => 'sortby')
    Session.continuous["sortby"].each_with_index do |f, i|
      # For the sale price, we need logic to figure out whether we are sorting either direction by price.
      if f == "saleprice_factor"
        if Session.search.sortby == "saleprice_factor"
          # We need to link to the descending sort order, but show the ascending arrow
          sortbyList << link_to(t(Session.product_type+".specs.saleprice_factor.name"), "#", :'data-feat' => 'saleprice_factor_high', :class => 'sortby') + image_tag("price_sorting_arrow_up.gif")
        elsif Session.search.sortby == "saleprice_factor_high"
          # We need to link to the ascending sort order, but show the descending arrow
          sortbyList << link_to(t(Session.product_type+".specs.saleprice_factor.name"), "#", :'data-feat' => 'saleprice_factor', :class => 'sortby') + image_tag("price_sorting_arrow_down.gif")
        else
          # If we haven't sorted by price yet, we should not show any arrow and link to the ascending price sort
          sortbyList << link_to(t(Session.product_type+".specs.saleprice_factor.name"), "#", :'data-feat' => 'saleprice_factor', :class => 'sortby')
        end
      else
        sortbyList << (Session.search.sortby == f ? t(Session.product_type+".specs."+f+".name") : link_to(t(Session.product_type+".specs."+f+".name"), "#", :'data-feat' => f, :class => 'sortby'))
      end
    end
    sortbyList.join("&nbsp;&nbsp;|&nbsp;&nbsp;")
    # select('sorting_method', @s.search.sortby, sortbyList, {:selected => @s.search.sortby}, {:id => "sorting_method"})
  end
end
