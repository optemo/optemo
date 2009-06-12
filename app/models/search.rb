class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :cluster
  has_many :vieweds
  
  #Array of normalized product counts
  def distribution(featureName)
    f = DbFeature.find_by_name_and_product_type(featureName,session.product_type)
    stepsize = (f.max-f.min)/10 
    res = []
    0..9.each do |i|
      min = f.min + stepsize*i
      max = min + stepsize
      chooseclusters = 0..cluster_count.map{|c| "cluster_id = #{send ('c'+c).intern}"}.join(' OR ')
      res << (session.product_type+'Node').constantize.find(:all, :conditions => ["#{featureName} < ? and #{featureName} >= ? and #{chooseclusters} ",max,min]).count
    end
    res
  end
  #Range of product offerings
  def ranges()
    
  end
end
