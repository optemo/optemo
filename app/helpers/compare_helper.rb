module CompareHelper
  def landing?
    ! (request.referer && request.referer.match(/http:\/\/(laserprinterhub|localhost)/))
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
    if Session.search.products_size > 1
      res = t("#{Session.product_type}.navtitle").pluralize
    else
        res = t("#{Session.product_type}.navtitle")
    end    
    res + t("#{Session.product_type}.navtitle2")
  end
 
  def chosencats(feat)
    Session.search.userdatacats.select{|d|d.name == feat}.map{|x|x.value}
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
  
  def category_select(feat)
    select('superfluous', feat, [t('products.add')+t(Session.product_type+'.specs.'+feat+'.name')] + CatSpec.count_feat(feat,true).map{|k,v| ["#{k} (#{v})", k]}, options={}, {:id => feat+"selector", :class => "selectboxfilter"})
  end
  
  def landing_main_boxes(type)
    res = ""
    res << '<div class="rowdiv">'
    prods = @s.search.products_landing
    num = prods.size-1
    # now the new mockup is only with featured products
    res << "<div class='title_landing_type'>" + I18n.t("products.featuredproducts") + "</div>"
    res << "<div style='clear:both;width: 0;height: 0;'><!--ie6/7 title disappear issue --></div>"
    for i in 0...num
        res << render(:partial => 'navbox', :locals => {:i => i, :product => Product.cached(prods[i+1].product_id), :landing => true})
        if (i%3) == 2
            if i != (num -1)
                res << '<div style="clear:both;height:1px;width: 520px;border-top:1px #ccc solid;margin: 0 auto;"></div>'
            end
        end
    end
    res << '<div style="clear:both;height:0;"></div></div>' if !@s.directLayout
  end
    
  def main_boxes
    res = ""
    for i in 0...@s.search.paginated_products.size
      if i % (Float(@s.numGroups)/3).ceil == 0
    	  res << '<div class="rowdiv">'
    	  open = true
      end
      #Navbox partial to draw boxes
      res << render(:partial => 'navbox', :locals => {:i => i, :product => Product.cached(@s.search.paginated_products[i].id), :landing=>false})
              if i % (Float(@s.numGroups)/3).ceil == (Float(@s.numGroups)/3).ceil - 1
                if i < (@s.search.paginated_products.size - 1)
                  res << '<div style="clear:both;height:1px;width: 520px;border-top:1px #ccc solid;margin:0 auto;"></div></div>'
                else
                  res << '<div style="clear:both;height:0;"></div></div>'
                end
                open = false
              end
    end
  	res << '<div style="clear:both;height:3px;width: 552px;margin-left: -1px;">&nbsp;</div></div>' if open && !@s.directLayout
    res << '<span id="actioncount" style="display:none">' + "#{[Session.search.id.to_s].pack("m").chomp}</span>"
  	res
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

  def capitalize_brand_name(name)
    brand_name = name.split(' ').map{|bn| bn=(bn==bn.upcase ? bn.capitalize : bn)}.join(' ')
  end

  def missing_spec_name_translation?(name)
    missing = false
    begin
      I18n::translate(Session.product_type + ".specs." + name + ".name", :raise => true)
    rescue I18n::MissingTranslationData
      missing = true
    end
    missing
  end

  def descurl(product)
    small_title(product).tr(' /','_-').tr('.', '-')
  end
  

  def navbox_display_title(product)
    title = small_title(product)
    if title.length > 43
      title = title[0..43].gsub(/\s[^\s]*$/,'')
    end
    title
  end
  
  def sortby
    current_sorting_option = Session.search.sortby || "utility"
    Session.features["sortby"].map { |f| content_tag :li, do
      text = t("specs."+f.name)
       (current_sorting_option == f.name) ? text : link_to(text, "#", {:'data-feat'=>f.name, :class=>"sortby"})
    end}.join(content_tag(:span, "  |  ", :class => "seperater"))
  end

end
