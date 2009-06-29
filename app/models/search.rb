require 'merged_cluster'
class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :cluster
  has_many :vieweds
  
  #Array of normalized product counts
  def distribution(featureName)
    f = DbFeature.find_by_name_and_product_type(featureName,session.product_type)
    stepsize = (f.max-f.min).to_f/10 
    res = []
    #debugger
    10.times do |i|
      min = f.min + stepsize*i
      max = min + stepsize
      clusters = []
      cluster_count.times do |c|
        clusters << "cluster_id = #{send(('c'+c.to_s).intern)}"
      end
      chooseclusters = clusters.join(' OR ')
      #Keyword search parameters
      options = session.searchpids.blank? ? '' : ' and ('+session.searchpids+')'
      #Filtering parameters
      options += session.filter && !Cluster.filterquery(session).blank? ? ' and '+Cluster.filterquery(session) : ''
      if max==min
        res << $nodemodel.find(:all, :conditions => ["#{featureName} = ? and (#{chooseclusters}) #{options}",max]).length
      else  
        res << $nodemodel.find(:all, :conditions => ["#{featureName} < ? and #{featureName} >= ? and (#{chooseclusters}) #{options}",max,min]).length
      end
    end
    round2Decim(normalize(res))
  end
  #Range of product offerings
  def ranges(featureName)
    min = clusters.map{|c|c.ranges(featureName,session)[0]}.compact.sort[0]
    max = clusters.map{|c|c.ranges(featureName,session)[1]}.compact.sort[-1]  
    [min, max]
  end
  
  def result_count
    clusters.map{|c| c.size(session)}.sum
  end
  
  def clusters
    if @clusters.nil?
      @clusters = []
      cluster_count.times do |i|
        cluster_id = send(:"c#{i}")
        if cluster_id.index('+')
          cluster_id.gsub(/[^(\d|+)]/,'') #Clean URL input
          #Merged Cluster
          c = MergedCluster.fromIDs(session.product_type,cluster_id.split('+'))
        else
          #Single, normal Cluster
          c = $clustermodel.find(cluster_id)
        end
        #Remove empty clusters
        if c.isEmpty(session)
          self.cluster_count -= 1
        else
          @clusters << c 
        end
      end
    end
    @clusters
  end
  
  def self.searchFromPath(path, session_id)
    ns = {}
    mycluster = 'c0'
    ns['cluster_count'] = path.length
    path.each do |p|
      ns[mycluster] = p
      mycluster.next!
    end
    ns['session_id'] = session_id
    s = new(ns)
    s['result_count'] = s.result_count
    s['parent_id'] = s.clusters.map{|c| c.parent_id}.sort[0]
    s['layer'] = s.clusters.map{|c| c.layer}.sort[0]
    s.save
    s
  end
  
  def to_s
    clusters.map{|c|c.id}.join('/')
  end
  
  def self.copySearch(olds)
    news = Search.new(olds.attributes)
  end  
  
  private
  
  def normalize(a)
    total = a.sum
    if total==0 
      a  
    else  
      a.map{|i| i.to_f/total} 
    end  
  end
  
  def round2Decim(a)
    a.map{|n| (n*1000).round.to_f/1000}
  end  
end
