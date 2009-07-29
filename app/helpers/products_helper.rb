module ProductsHelper
  def nav_link
    
    if request.env['HTTP_REFERER'] && request.env['HTTP_REFERER'].match('laserprinterhub|localhost')
      link_to 'Go back<br> to navigation', 'javascript:history.back()'
    else
      link_to 'Browse more products', :controller => 'products'
    end
    
  end

  def array_to_csv(iArray)
    # converts iArray, an array of integers, to a string in csv format
    csv = ""
    for i in 0..iArray.count-1
      csv = csv + iArray[i] + ","
    end
    # Chop off the last comma
    csv = csv.chop    
    csv
  end

  def sim_link(cluster,i, itemId)
    unless cluster.children(@session).nil? || cluster.children(@session).empty? || (cluster.size(@session)==1)
      "<div class='sim'>" +
        link_to("#{cluster.size(@session)-1} More Product#{"s" if cluster.size(@session) > 2} In This Group", 
        "/#{$model.urlname}/compare/"+cluster.children(@session).map{|c|c.id}.join('-'), 
        :id => "sim#{i}", :class => 'simlinks', :name => itemId) +
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
  
  def dbmin(i2f, feat)
    i2f ? @dbfeat[feat].min/100 :  @dbfeat[feat].min.to_i
  end
  
  def dbmax(i2f, feat)
    i2f ? (@dbfeat[feat].max.to_f/100).ceil : @dbfeat[feat].max.ceil
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
end