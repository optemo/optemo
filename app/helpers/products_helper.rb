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