class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :cluster
  has_many :vieweds
  
  #Array of normalized product counts
  def distribution(featureName)
    f = DbFeature.find_by_name_and_product_type(featureName,session.product_type)
    stepsize = (f.max-f.min)/10 
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
        res << (session.product_type+'Node').constantize.find(:all, :conditions => ["#{featureName} = ? and #{chooseclusters} ",max]).length
      else  
        res << (session.product_type+'Node').constantize.find(:all, :conditions => ["#{featureName} < ? and #{featureName} >= ? and #{chooseclusters} ",max,min]).length
      end
    end
    normalize(res)
  end
  #Range of product offerings
  def ranges()
    
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
end
