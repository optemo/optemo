module Cluster
  #The subclusters
  def children(session)
    unless @children
      @children = self.class.find_all_by_parent_id(id, :order => 'cluster_size DESC')
      #Check that children are not empty
      if session.filter || !session.searchpids.blank?
        @children.delete_if{|c| c.isEmpty(session)}
      end
    end
    @children
  end
  
  
  # finding the deepChildren(clusters with size 1) in clusters
  def deepChildren(session, dC = [])
    #store the cluster id if the cluster_size is 1 and the cluster accepts the filtering conditions 
    if (self.cluster_size == 1) && (self.size(session)>0)
      dC << self
    else
      mychildren = self.class.find_all_by_parent_id(id)
      mychildren.each do |mc|
          dC = mc.deepChildren(session, dC)
      end  
    end 
    dC
  end

  
  def ranges(featureName, session)
    @range ||= {}
    if @range[featureName].nil?
      unless session.filter || !session.searchpids.blank?
        @range[featureName] = [send(featureName+'_min'), send(featureName+'_max')]
      else
        values = nodes(session).map{|n| n.send(featureName)}.sort
        nodes_min = values[0]
        nodes_max = values[-1]
        @range[featureName] = [nodes_min, nodes_max]    
      end
    end
    @range[featureName]
  end
  
  def nodes(session)
    unless @nodes
      @nodes = $nodemodel.find(:all, :order => 'price ASC', :conditions => ["cluster_id = ?#{session.filter && !Cluster.filterquery(session).blank? ?
         ' and '+Cluster.filterquery(session) : ''}#{session.searchpids.blank? ? '' : ' and ('+session.searchpids+')'}",id])
    end
    @nodes
  end
  
  #The represetative product for this cluster
  def representative(session)
    unless @rep
      node = nodes(session).first
      @rep = $model.find(node.product_id) if node
    end
    @rep
  end
  
  def self.filterquery(session)
    fqarray = []
    filters = Cluster.findFilteringConditions(session)
    filters.each_pair do |k,v|
      unless v.nil? || v == 'All Brands'
        if k.index(/(.+)_max$/)
          fqarray << "#{Regexp.last_match[1]} <= #{v}"
        elsif k.index(/(.+)_min$/)
          fqarray << "#{Regexp.last_match[1]} >= #{v}"
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
  
  def size(session)
    unless @size
      if session.filter || !session.searchpids.blank?
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
        return 'Empty' if clusterR[0].nil? || clusterR[1].nil?
        if (clusterR[1]<=low)
          des <<  $model::ContinuousFeaturesDescLow[f.name]
        elsif (clusterR[0]>=high)
          des <<  $model::ContinuousFeaturesDescHigh[f.name]
        end
      end 
      res = des.join(', ')
      res.blank? ? 'All Purpose' : res
  end
  
  
  def self.findFilteringConditions(session)
    session.attributes.delete_if {|key, val| !(key.index(/#{($model::ContinuousFeatures.map{|f|f+'_(max|min)'}+$model::CategoricalFeatures+$model::BinaryFeatures).join('|')}/))}
  end
  
  def isEmpty(session)
    nodes(session).empty?
  end
end