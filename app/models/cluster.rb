module Cluster
  include CachingMemcached
  #The subclusters
  def children(session, searchpids)
    unless @children
      @children = self.class.find_all_by_parent_id(id)
      #Check that children are not empty
      if session.filter
        @children.delete_if{|c| c.isEmpty(session, searchpids)}
      end
    end
    @children
  end
  
  
  # finding the deepChildren(clusters with size 1) in clusters
  def deepChildren(session, searchpids, dC = [])
    #store the cluster id if the cluster_size is 1 and the cluster accepts the filtering conditions 
    if (self.cluster_size == 1) && (self.size(session, searchpids)>0)
      dC << self
    else
      mychildren = self.class.find_all_by_parent_id(id)
      mychildren.each do |mc|
          dC = mc.deepChildren(session, searchpids, dC)
      end  
    end 
    dC
  end
  
  def ranges(featureName, session, searchpids)
    @range ||= {}
    if @range[featureName].nil?
      unless session.filter
        @range[featureName] = [send(featureName+'_min'), send(featureName+'_max')]
      else
        values = nodes(session, searchpids).map{|n| n.send(featureName)}.sort
        nodes_min = values[0]
        nodes_max = values[-1]
        @range[featureName] = [nodes_min, nodes_max]    
      end
    end
    @range[featureName]
  end

# this could be integrated with ranges later
  def indicator(featureName, session, searchpids)
    indic = false
     unless session.filter
        indic = send(featureName)
     else
        values = nodes(session, searchpids).map{|n| n.send(featureName)}
        if values.index(false).nil? # they are all the same
            indic = true
        end      
     end
     indic
  end
  
  def nodes(session,searchpids)
    unless @nodes
      @nodes = $nodemodel.find(:all, :conditions => ["cluster_id = ?#{session.filter && !Cluster.filterquery(session).blank? ?
         ' and '+Cluster.filterquery(session) : ''}#{!session.filter || searchpids.blank? ? '' : ' and ('+searchpids+')'}",id])
    end
    @nodes
  end
  
  #The represetative product for this cluster
  def representative(session, searchpids)
    unless @rep
      node = nodes(session, searchpids).first
      @rep = findCachedProduct(node.product_id) if node
    end
    @rep
  end
  
  def self.filterquery(session)
    fqarray = []
    filters = Cluster.findFilteringConditions(session)
    filters.each_pair do |k,v|
      unless v.nil? || v == 'All Brands'
        if k.index(/(.+)_max$/)
          fqarray << "#{Regexp.last_match[1]} <= #{v.class == Float ? v+0.00001 : v}"
        elsif k.index(/(.+)_min$/)
          fqarray << "#{Regexp.last_match[1]} >= #{v.class == Float ? v-0.00001 : v}"
        #Categorical feature which needs to be deliminated
        elsif v.class == String && v.index('*')
          cats = []
          v.split('*').each do |w|
            cats << "#{k} = '#{w}'"
          end
          fqarray << "(#{cats.join(' OR ')})"
        elsif v.class == String
          fqarray << "#{k} = '#{v}'"
        else
          fqarray << "#{k} = #{v}"
        end
      end
    end
    fqarray.join(' AND ')
  end
  
  def size(session, searchpids)
    unless @size
      if session.filter
        @size = nodes(session, searchpids).length
      else
        @size = cluster_size
      end
    end
    @size
  end
  #Description for each cluster
  def description(session, searchpids)
    des = []
    $dbfeat.each do |f|
      if (f.featureType == 'Continuous')
        low = f.low
        high = f.high  
        clusterR = ranges(f.name, session, searchpids)
        return 'Empty' if clusterR[0].nil? || clusterR[1].nil?
        if (clusterR[1]<=low)
          des <<  $model::ContinuousFeaturesDescLow[f.name]
        elsif (clusterR[0]>=high)
          des <<  $model::ContinuousFeaturesDescHigh[f.name]
        end
      end  
    end 
      res = des.join(', ')
      res.blank? ? 'All Purpose' : res
  end
  
  
  def self.findFilteringConditions(session)
    session.features.attributes.reject {|key, val| key=='id' || key=='session_id' || key.index('_pref') || key=='created_at' || key=='updated_at' || key=='search_id'}
  end
  
  def isEmpty(session, searchpids)
    nodes(session, searchpids).empty?
  end
  
  def clearCache
    @nodes = nil
    @size = nil
    @rep = nil
    @range = nil
    @children = nil
    @utility = nil
  end
  
  def utility(session, searchpids)
    cached_utility
  end
end