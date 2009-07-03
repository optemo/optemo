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

  def sim_link(cluster,i, sess)
    itemId = cluster.representative(@session).id.to_i
    # Link to sim_redirect action, and pass selected item's Id, path_info, 
    # and the page to redirect_to after database operation as query
    pathInfo = params[:path_info]
    # pathInfo is an array. Convert into string
    path_info = array_to_csv(pathInfo)
    unless cluster.children(@session).nil? || cluster.children(@session).empty? || (cluster.size(@session)==1)
      "<div class='sim'>" +
      link_to("Explore #{cluster.size(@session)} Similar Product#{"s" if cluster.size(@session) > 1}",
      "/products/sim_redirect?id=sim#{i}&itemId=" + itemId.to_s + "&path_info=" + path_info + "&query=" + "/#{!session[:productType].nil? ? session[:productType].pluralize.downcase : $DefaultProduct.pluralize.downcase}/list/"+cluster.children(@session).map{|c|c.id}.join('/')) +
      "</div>"
    else
      ""
    end
=begin    # Id of the chosen item
        itemId = cluster.representative(@session).id.to_i
        # Populate otherItems string, in CSV format
        otherItems = ""
      	for i in 0..sess.cluster_count-1
      	  if(sess.clusters[i].representative(@session).id != itemId)
      	    otherItems = otherItems + sess.clusters[i].representative(@session).id.to_s + ","
    	    end
    	  end
    	  # Chop off the last comma
    	  otherItems = otherItems.chop
      	# Link to sim_redirect action, and pass selected item's Id, other items' Ids, 
      	# and the page to redirect_to after database operation as query
      	unless cluster.children(@session).nil? || cluster.children(@session).empty? || (cluster.size(@session)==1)
          "<div class='sim'>" +
            link_to("Explore #{cluster.size(@session)} Similar Product#{"s" if cluster.size(@session) > 1}",
            "/products/sim_redirect?id=sim#{i}&itemId=" + itemId.to_s + "&otherItems=" + otherItems + "&query=" + "/#{!session[:productType].nil? ? session[:productType].pluralize.downcase : $DefaultProduct.pluralize.downcase}/list/"+cluster.children(@session).map{|c|c.id}.join('/')) +
          "</div>"
        else
          ""
        end
=end
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
  
  def dbmin(feat)
    feat=='price' ? @dbfeat['price'].min/100 :  @dbfeat[feat].min.to_i
  end
  
  def dbmax(feat)
    feat=='price' ? (@dbfeat['price'].max.to_f/100).ceil : @dbfeat[feat].max.ceil
  end
end

# this function gets an stack of searches and gets rid of the ones with repetitive
# layer numbers
def zipStack(stack)
  
   allSearches = []
   i=0
   until (stack[-1 -i].layer == 1)
     s = stack[-1-i]
     ls = allSearches.map{|r| r.layer}
   
     if (ls.index(s.layer).nil?)
        if (ls.empty?)
          allSearches.unshift(s)
        elsif (ls[0] > s.layer)
          allSearches.unshift(s) 
        end  
     end   
     i = i+1
   end    
   allSearches.unshift(stack[-1-i]) if (stack[-1-i].layer==1)  
   layer = allSearches[-1].layer
  
   # When can't reach the first layer in the given time frame 
   # Must create searches for higher layers
   l = allSearches[0].layer
   unless l == 1 
        pid =  allSearches[0].parent_id
        r = Search.new 
        cluster = $clustermodel.find(pid)            
        while (l>1)
           mycluster = 'c0'
           ppid = cluster.parent_id  
           cs = $clustermodel.find_all_by_parent_id(ppid)
           cs.each do |c|
             r[mycluster] = c.id.to_s
             mycluster.next!
           end  
        end   
        r['parent_id'] = pid2
        allSearches.unshift(r)
   end
   
   return layer, allSearches
end