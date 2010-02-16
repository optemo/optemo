module Cluster
  include CachingMemcached
  #The subclusters
  def children
    unless @children
      @children = self.class.find_all_by_parent_id(id)
      #Check that children are not empty
      if Session.current.filter
        @children.delete_if{|c| c.isEmpty}
      end
    end
    @children
  end
  
  # finding the deepChildren(clusters with size 1) in clusters
  def deepChildren(dC = [])
    #store the cluster id if the cluster_size is 1 and the cluster accepts the filtering conditions 
    if (self.cluster_size == 1) && (self.size>0)
      dC << self
    else
      mychildren = self.class.find_all_by_parent_id(id)
      mychildren.each do |mc|
          dC = mc.deepChildren(dC)
      end  
    end 
    dC
  end
  
  def ranges(featureName)
    @range ||= {}
    if @range[featureName].nil?
      unless Session.current.filter
        @range[featureName] = [send(featureName+'_min'), send(featureName+'_max')]
      else
        values = nodes.map{|n| n.send(featureName)}.sort
        nodes_min = values[0]
        nodes_max = values[-1]
        @range[featureName] = [nodes_min, nodes_max]    
      end
    end
    @range[featureName]
  end

# this could be integrated with ranges later
  def indicator(featureName)
    indic = false
     unless Session.current.filter
        indic = send(featureName)
     else
        values = nodes.map{|n| n.send(featureName)}
        if values.index(false).nil? # they are all the same
            indic = true
        end      
     end
     indic
  end
  
  def nodes
    unless @nodes
      if ((Session.current.filter && !Cluster.filterquery(Session.current).blank?) || !Session.current.keywordpids.blank?)
        @nodes = $nodemodel.find(:all, :conditions => ["cluster_id = ?#{Session.current.filter && !Cluster.filterquery(Session.current).blank? ? ' and '+Cluster.filterquery(Session.current) : ''}#{!Session.current.filter || Session.current.keywordpids.blank? ? '' : ' and ('+Session.current.keywordpids+')'}",id])
      else 
        @nodes = findCachedNodes(id)
      end
    end
    @nodes
  end
  
  #The represetative product for this cluster
  def representative
    unless @rep
      node = nodes.first
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
  
  def size
    unless @size
      if Session.current.filter
        @size = nodes.length
      else
        @size = cluster_size
      end
    end
    @size
  end
  
  def self.findFilteringConditions(session)
    session.features.attributes.reject {|key, val| key=='id' || key=='session_id' || key.index('_pref') || key=='created_at' || key=='updated_at' || key=='search_id'}
  end
  
  def isEmpty
    nodes.empty?
  end
  
  def clearCache
    @nodes = nil
    @size = nil
    @rep = nil
    @range = nil
    @children = nil
    @utility = nil
  end
  
  def utility
    cached_utility
  end
end