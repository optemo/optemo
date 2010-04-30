class Cluster < ActiveRecord::Base
  has_many :nodes
  has_many :products, :through => :nodes
  has_many :cont_specs, :through => :products
  has_many :bin_specs, :through => :products
  
  def self.byparent(id)
    current_version = Session.current.version
    CachingMemcached.cache_lookup("Clusters#{current_version}#{id}"){find_all_by_parent_id_and_version_and_product_type(id, current_version, $product_type)}
  end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Cluster#{id}"){find(id)}
  end
  
  #The subclusters
  def children
    unless @children
      @children = byparent(id)
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
      mychildren = byparent(id)
      mychildren.each do |mc|
          dC = mc.deepChildren(dC)
      end  
    end 
    dC
  end
  
  #Maybe we can cache this ***We need a join here
  def ranges(featureName)
    @range ||= {}
    if @range[featureName].nil?
      nodes_min = cont_specs.select{|s|s.name == featurename}.map(&:min).sort[0]
      nodes_max = cont_specs.select{|s|s.name == featurename}.map(&:max).sort[-1]
      @range[featureName] = [nodes_min, nodes_max]    
    end
    @range[featureName]
  end

# this could be integrated with ranges later
  def indicator(featureName)
    indic = false
      values = bin_specs.select{|s|s.name == featurename}
      if values.index(false).nil? # they are all the same
          indic = true
      end 
    indic
  end
  
  def nodes
    unless @nodes
      if ((Session.current.filter && !Cluster.filterquery(Session.current).blank?) || !Session.current.keywordpids.blank?)
        @nodes = Node.find(:all, :conditions => ["cluster_id = ?#{Session.current.filter && !Cluster.filterquery(Session.current).blank? ? ' and '+Cluster.filterquery(Session.current) : ''}#{!Session.current.filter || Session.current.keywordpids.blank? ? '' : ' and ('+Session.current.keywordpids+')'}",id])
      else 
        @nodes = Node.bycluster(id)
      end
    end
    @nodes
  end
  
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    Product.cached(nodes.first.product_id)
  end
  
  def self.filterquery(session, tablename="")
    fqarray = []
    filters = Cluster.findFilteringConditions(session)
    filters.each_pair do |k,v|
      unless v.nil? || v == 'All Brands'
        if k.index(/(.+)_max$/)
          fqarray << "#{tablename}#{Regexp.last_match[1]} <= #{v.class == Float ? v+0.00001 : v}"
        elsif k.index(/(.+)_min$/)
          fqarray << "#{tablename}#{Regexp.last_match[1]} >= #{v.class == Float ? v-0.00001 : v}"
        #Categorical feature which needs to be deliminated
        elsif v.class == String && v.index('*')
          cats = []
          v.split('*').each do |w|
            cats << "#{tablename}#{k} = '#{w}'"
          end
          fqarray << "(#{cats.join(' OR ')})"
        elsif v.class == String
          fqarray << "#{tablename}#{k} = '#{v}'"
        else
          fqarray << "#{tablename}#{k} = #{v}"
        end
      end
    end
    fqarray.join(' AND ')
  end
  
  def size
    nodes.length
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
    nodes.map{|n|n.utility}.sum/size
  end
end
