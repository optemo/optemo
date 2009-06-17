module Cluster
  def getHistory
    history = []
    currentCluster = self
    while ((c = currentCluster.parent_id) != 0)
      currentCluster = self.class.find(c)
      history << currentCluster
    end
    history
  end
  
  #The subclusters
  def children(session)
    unless @children
      @children = self.class.find_all_by_parent_id(id)
      #Check that children are not empty
      if session.filter
        f = Cluster.findFilteringConditions(session)
        @children.delete_if{|c| c.isEmpty(f,session.product_type)}
      end
    end
    @children
  end
  
  def ranges(featureName, session)
    unless session.filter
      
      [send(featureName+'_min'), send(featureName+'_max')]
    else
      nodeclass = session.product_type + 'Node'
      #return [nil,nil] if nodes(session).nil?
      values = nodes(session).map{|n| n.send(featureName)}.sort
      nodes_min = values[0]
      nodes_max = values[-1] 
      [nodes_min, nodes_max]    
    end 
  end
  
  def nodes(session)
    unless @nodes
      @nodes = (session.product_type + 'Node').constantize.find(:all, :order => 'price ASC', 
        :conditions => ["cluster_id = ?#{session.filter ? " and "+Cluster.filterquery(session) : ''}",id])
    end
    @nodes
  end
  
  #The represetative product for this cluster
  def representative(session)
    node = nodes(session).first
    session.product_type.constantize.find(node.product_id) if node
  end
  
  def self.filterquery(session)
    fqarray = []
    Cluster.findFilteringConditions(session).each_pair do |k,v|
      unless v.nil? || v == 'All Brands'
        if k.index(/(.+)_max$/)
          fqarray << "#{Regexp.last_match[1]} <= #{v}"
          #fqarray << "#{k} <= #{v}"
        elsif k.index(/(.+)_min$/)
          fqarray << "#{Regexp.last_match[1]} >= #{v}"
          #fqarray << "#{k} >= #{v}"
        else
          fqarray << "#{k} = '#{v}'"
        end
      end
    end
    fqarray.join(' AND ')
  end
  
  
  def size(session)
    unless @size
      if session.filter
        nodeclass = session.product_type + 'Node'
        @size = nodes(session).length
      else
        @size = cluster_size
      end
    end
    @size
  end
  #Description for each cluster
  def description(session)
    des = []
    DbFeature.find_all_by_product_type_and_feature_type(session.product_type, 'Continuous').each do |f|
        low = f.low
        high = f.high  
        clusterR = ranges(f.name, session)
        if (clusterR[1]<=low)
          des <<  session.product_type.constantize::ContinuousFeaturesDescLow[f.name]
        elsif (clusterR[0]>=high)
          des <<  session.product_type.constantize::ContinuousFeaturesDescHigh[f.name]
        end
      end 
      res = des.join(', ')
      res.blank? ? "All Purpose" : res
  end
  
  
  def self.findFilteringConditions(session)
    atts = session.attributes
    atts.delete_if {|key, val| !(key.index(/#{(session.product_type.constantize::ContinuousFeatures.map{|f|f+'_(max|min)'}+session.product_type.constantize::CategoricalFeatures+session.product_type.constantize::BinaryFeatures).join('|')}/))}
  end
  
  def isEmpty(filters, product_type)
    empty = false
    product_type.constantize::ContinuousFeatures.each do |f|
      unless filters[f+'_max'].nil? || filters[f+'_max'].nil?
        if send((f+'_min').intern) > filters[f+'_max'] || send((f+'_max').intern) < filters[f+'_min']
          empty = true
          break
        end
      end
    end
    product_type.constantize::BinaryFeatures.each do |f|
      unless filters[f].nil?
        if filters[f] && !send(f.intern)
          empty = true
          break
        end
      end
    end if !empty
    #product_type.constantize::CategoricalFeatures.each do |f|
    #  if filters.key?(f) && filters['brand'] != "All Brands"
    #    cats = filters[f].split('*')
    #    clustercats = send(f.intern).split('*')
    #    if (cats & clustercats).empty?
    #      empty = true
    #      break
    #    end
    #  end
    #end if !empty
    empty
  end
  
  
end