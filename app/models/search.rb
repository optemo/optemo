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
      if max==min
        res << (session.product_type+'Node').constantize.find(:all, :conditions => ["#{featureName} = ? and (#{chooseclusters}) ",max]).length
      else  
        res << (session.product_type+'Node').constantize.find(:all, :conditions => ["#{featureName} < ? and #{featureName} >= ? and (#{chooseclusters}) ",max,min]).length
      end
    end
    round2Decim(normalize(res))
  end
  #Range of product offerings
  def ranges(featureName)
    f = DbFeature.find_by_name_and_product_type(featureName,session.product_type)
    if featureName == 'price'
      [f.min.to_f/100, f.max.to_f/100]
    else
      [f.min, f.max]
    end    
  end
  
  def result_count
    clusters.map{|c| c.cluster_size}.sum
  end
  
  def clusters
    if @clusters.nil?
      @clusters = []
      cluster_count.times do |i|
        @clusters << (session.product_type+'Cluster').constantize.find(send(:"c#{i}"))
      end
    end
    @clusters
  end
  
  def self.searchFromPath(path, session)
    ns = {}
    mycluster = 'c0'
    ns['cluster_count'] = path.length
    path.each do |p|
      ns[mycluster] = p
      mycluster.next!
    end
    #s = Session.find(session[:user_id])
    ns['session_id'] = session.id
    #ns['parent_id'] = s
    s = new(ns)
    s.save
    s
  end
  
  def to_s
    clusters.join('/')
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
