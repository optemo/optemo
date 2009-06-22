module ProductsHelper
  def nav_link
    
    if request.env['HTTP_REFERER'] && request.env['HTTP_REFERER'].match('laserprinterhub|localhost')
      link_to 'Go back<br> to navigation', 'javascript:history.back()'
    else
      link_to 'Browse more products', :controller => 'products'
    end
    
  end
  
  def sim_link(cluster,i)
  	unless cluster.children(@session).nil? || cluster.children(@session).empty? || (cluster.size(@session)==1)
      "<div class='sim'>" +
        link_to("Explore #{cluster.size(@session)} Similar Product#{"s" if cluster.size(@session) > 1}", 
        "/#{!session[:productType].nil? ? session[:productType].pluralize.downcase : $DefaultProduct.pluralize.downcase}/list/"+cluster.children(@session).map{|c|c.id}.join('/'), 
        :id => "sim#{i}") +
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
  
  def history(mytype)
    @s.clusters[0].getHistory.reverse
  end
  
  def dbmin(feat)
    feat=='price' ? @dbfeat['price'].min/100 :  @dbfeat[feat].min.to_i
  end
  
  def dbmax(feat)
    feat=='price' ? (@dbfeat['price'].max.to_f/100).ceil : @dbfeat[feat].max.ceil
  end
end
