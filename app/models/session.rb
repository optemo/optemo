class Session < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :searches
  
  def clearFilters
    Session.column_names.delete_if{|i| %w(id created_at updated_at ip parent_id product_type).index(i)}.each do |name|
      send((name+'=').intern, Session.columns_hash[name].default)
    end
    save
  end
  
  def self.ip_uniques
    old = ["72.30.65.46", "66.249.68.102", "72.30.79.84", "174.6.50.250", "66.249.68.14", "24.86.24.240", "207.118.66.198", "142.103.18.59", "98.17.159.209", "64.246.165.50", "72.181.134.155", "216.34.209.23", "174.129.150.167", "74.55.161.226", "199.175.128.1", "174.6.9.123", "93.158.144.28", "70.79.182.171", "206.116.49.215", "74.6.22.96", "66.249.66.144", "209.121.122.158", "38.105.83.12", "66.235.124.56", "204.62.53.203", "68.110.246.81", "72.14.194.1", "71.132.195.152", "71.132.213.136", "209.202.168.79", "66.249.71.87", "209.202.168.73", "174.6.50.241", "69.58.178.31", "192.197.106.86", "209.202.168.81", "64.246.165.190", "204.244.194.35", "209.202.168.80", "209.202.168.77", "66.79.89.242", "66.249.72.101", "75.157.148.57", "66.249.67.14", "216.16.248.136", "67.202.41.3", "75.101.227.178", "24.207.92.134", "201.240.88.217", "192.197.121.107", "192.197.121.109", "220.233.64.15", "74.201.117.226", "117.199.197.154", "96.48.140.152", "70.75.78.209", "174.6.174.141", "70.79.85.0", "91.187.4.200", "216.241.231.100", "75.157.187.83", "207.216.69.84", "70.79.157.173", "24.83.243.193", "174.6.20.7", "66.249.68.38", "38.105.86.201", "142.58.249.155", "142.58.240.33", "206.186.74.5", "66.249.68.58", "96.53.217.238", "66.249.68.105", "97.74.127.171", "130.83.142.31"]
    (self.all.map{|s|s.ip}+old).uniq.delete_if{|i|i =~ /^(192\.168.|127.0.|::1)/}
  end
  
  def self.ip_total
    self.all.map{|s|s.ip}.delete_if{|i|i =~ /^(192\.168.|127.0.|::1)/}
  end
  
  def createFromFilters(myfilter)
    # Create two objects, mysession and myfeatures
    # mysession stores attributes for the sessions table
    # myfeatures stores attributes for the "Product"Features table 
    feature_filter = {}
    #Delete blank values
    myfilter.delete_if{|k,v|v.blank?}
    #Fix price, because it's stored as int in db
    feature_filter[:price_max] = (myfilter.delete(:price_max)*100).to_i if myfilter[:price_max]
    feature_filter[:price_min] = (myfilter.delete(:price_min)*100).to_i if myfilter[:price_min]
    (product_type + 'Features').constantize.column_names.each do |column|
      if !(column == 'id' || column == 'session_id')# || column == 'price_max' || column == 'price_min')
        feature_filter[column.intern] = myfilter.delete(column.intern) if myfilter[column.intern]
      end
    end 
    myfilter = handle_false_booleans(myfilter)
    myfilter[:parent_id] = id
    myfilter[:filter] = true
    feature_filter[:brand] = myfilter.delete(:brand)   
    # feature_filter[:session_id] = myfilter[:id] 
    mysession =  Session.new(attributes.merge(myfilter))
    mysession.features = (product_type + 'Features').constantize.new(feature_filter)  # (attributes.merge(feature_filter))
    mysession
  end
 
  def clusters
    #Find clusters that match filtering query
    @oldsession = Session.find(parent_id)
    if expandedFiltering?
      #Search is expanded, so use all products to begin with
      clusters = $clustermodel.find_all_by_layer(1)
    else
      #Search is narrowed, so use current products to begin with
      clusters = []
      clusters = @oldsession.oldclusters
    end
    clusters.delete_if{|c| c.isEmpty(self)}
    fillDisplay(clusters)
  end
  
  def oldclusters
    searches.last.clusters
  end
  
  def commit
    @oldsession = Session.find(parent_id) unless @oldsession
    #Save search values
    @oldsession.update_attributes(attributes)
    # => features.session_id = @oldsession.id
    features.commit(@oldsession.id)
    #f = (product_type + 'Features').constantize.find(:first, :conditions => ['session_id = ?', @oldsession.id])
    #f.update_attributes(features)
  end
  
  def features=(f)
    @features = f
  end
        
  def features
    #Return row of Product's Feature table
    unless @features
      @features = (product_type + 'Features').constantize.find(:first, :conditions => ['session_id = ?', id])
    end
    @features
  end
  
  private
  
  def handle_false_booleans(myfilter)
    $model::BinaryFeatures.each do |f|
      myfilter.delete(f) if myfilter[f] == '0' && features.send(f.intern) != true
    end
    myfilter
  end
  
  def expandedFiltering?
    attributes.keys.each do |key|
      if key.index(/(.+)_min/)
        fname = Regexp.last_match[1]
        max = fname+'_max'
        maxv = @oldsession.send(max.intern)
        next if maxv.nil?
        oldrange = maxv - @oldsession.send(key.intern)
        newrange = attributes[max] - attributes[key]
        return true if newrange > oldrange
      elsif key.index(/#{$model::BinaryFeatures.join('|')}/)
        if attributes[key] == false
          #Only works for one item submitted at a time
          send((key+'=').intern, nil)
          return true 
        end
      elsif key.index(/#{$model::CategoricalFeatures.join('|')}/)
        oldv = @oldsession.send(key.intern)
        if oldv
          new_a = attributes[key] == "All Brands" ? [] : attributes[key].split('*')
          old_a = oldv == "All Brands" ? [] : oldv.split('*')
          return true if new_a.length < old_a.length
        end
      end
    end
    false
  end
  
  def splitClusters(clusters)
    while clusters.length != 9
      clusters.sort! {|a,b| b.size(self) <=> a.size(self)}
      clusters = split(clusters.shift.children(self)) + clusters
    end
    clusters.sort! {|a,b| b.size(self) <=> a.size(self)}
  end
  
  def split(children)
    return children if children.length == 1
    children.sort! {|a,b| b.size(self) <=> a.size(self)}
    [children.shift, MergedCluster.new(children)]
  end
  
  def fillDisplay(clusters)
    if clusters.length < 9
      if clusters.map{|c| c.size(self)}.sum >= 9
        clusters = splitClusters(clusters)
      else
        #Display only the deep children
        clusters = clusters.map{|c| c.deepChildren(self)}.flatten
      end
    end
    clusters
  end
    
end
