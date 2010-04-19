class Session < ActiveRecord::Base
  include CachingMemcached
  has_many :vieweds
  has_many :searches
  has_many :preference_relations
  
  attr :oldfeatures, true
  attr :keyword, true
  attr :keywordpids, true
  attr :version, true
  attr :search, true
  def self.current
    @@current
  end
  
  def self.current=(s)
    @@current = s
  end
  
  def clearFilters
    # In Sessions table, 
    # Set all attributes except some, to their default values
    #saves = []
    #Session.column_names.delete_if{|i| %w(id created_at updated_at ip parent_id product_type actioncount offeredsurvey).index(i)}.each do |name|
    #  saves << name unless send(name.intern).nil?
    #end
    #update_attributes(Hash[*saves.zip([nil]*saves.length).flatten]) unless saves.empty?
    ## In Product-features table,
    ## Set all attributes (EXCEPT id,session_id, created_at, updated_at & all the preference values) to defaults
    #saves = []
    #$featuremodel.column_names.delete_if {|key, val| key=='id' || key=='session_id' || key.index('_pref') || key=='created_at' || key=='updated_at'}.each do |name|
    #  saves << name unless features.send(name.intern).nil?
    #end
    #features.update_attributes(Hash[*saves.zip([nil]*saves.length).flatten]) unless saves.empty?
    
    update_attribute('filter',false) if (filter == true)
    saves = []
    $featuremodel.column_names.delete_if {|key, val| key=='id' || key=='session_id' || key.index('_pref') || key=='created_at' || key=='updated_at'}.each do |name|
      saves << name unless features.send(name.intern).nil?
    end
    unless saves.empty?
      @features = $featuremodel.new({'session_id' => id})
      @features.save
    end
  end
  
  def self.ip_uniques
    old = ["66.249.67.14", "66.183.30.8", "24.82.139.61", "24.86.24.240", "66.32.52.246", "66.249.68.102", "72.30.65.46", "38.108.180.114", "38.108.180.58", "72.30.87.84", "74.201.117.226", "216.34.209.23", "206.80.5.2", "65.55.211.76", "65.55.110.63", "216.19.180.83", "89.123.186.17", "67.228.88.42", "67.202.41.3", "65.55.108.195", "65.196.0.74", "24.16.40.13", "68.63.43.13", "72.94.249.34", "61.9.203.141", "77.88.30.246", "134.58.253.55", "199.60.13.86", "85.75.125.187", "72.30.79.84", "174.6.50.250", "66.249.68.14", "207.118.66.198", "142.103.18.59", "98.17.159.209", "64.246.165.50", "72.181.134.155", "174.129.150.167", "74.55.161.226", "199.175.128.1", "174.6.9.123", "93.158.144.28", "70.79.182.171", "206.116.49.215", "74.6.22.96", "66.249.66.144", "209.121.122.158", "38.105.83.12", "66.235.124.56", "204.62.53.203", "68.110.246.81", "72.14.194.1", "71.132.195.152", "71.132.213.136", "209.202.168.79", "66.249.71.87", "209.202.168.73", "174.6.50.241", "69.58.178.31", "192.197.106.86", "209.202.168.81", "64.246.165.190", "204.244.194.35", "209.202.168.80", "209.202.168.77", "66.79.89.242", "66.249.72.101", "75.157.148.57", "216.16.248.136", "75.101.227.178", "24.207.92.134", "201.240.88.217", "192.197.121.107", "192.197.121.109", "220.233.64.15", "117.199.197.154", "96.48.140.152", "70.75.78.209", "174.6.174.141", "70.79.85.0", "91.187.4.200", "216.241.231.100", "75.157.187.83", "207.216.69.84", "70.79.157.173", "24.83.243.193", "174.6.20.7", "66.249.68.38", "38.105.86.201", "142.58.249.155", "142.58.240.33", "206.186.74.5", "66.249.68.58", "96.53.217.238", "66.249.68.105", "97.74.127.171", "130.83.142.31"]
    (self.all.map{|s|s.ip}+old).uniq.delete_if{|i|i =~ /^(192\.168.|127.0.|::1)/}
  end
  
  def self.ip_total
    self.all.map{|s|s.ip}.delete_if{|i|i =~ /^(192\.168.|127.0.|::1)/}
  end
  
  def self.isCrawler?(str)
    str.match(/Google|msnbot|Rambler|Yahoo|AbachoBOT|accoona|AcioRobot|ASPSeek|CocoCrawler|Dumbot|FAST-WebCrawler|GeonaBot|Gigabot|Lycos|MSRBOT|Scooter|AltaVista|IDBot|eStyle|ScrubbyBloglines subscriber|Dumbot|Sosoimagespider|QihooBot|FAST-WebCrawler|Superdownloads Spiderman|LinkWalker|msnbot|ASPSeek|WebAlta Crawler|Lycos|FeedFetcher-Google|Yahoo|YoudaoBot|AdsBot-Google|Googlebot|Scooter|Gigabot|Charlotte|eStyle|AcioRobot|GeonaBot|msnbot-media|Baidu|CocoCrawler|Google|Charlotte t|Yahoo! Slurp China|Sogou web spider|YodaoBot|MSRBOT|AbachoBOT|Sogou head spider|AltaVista|IDBot|Sosospider|Yahoo! Slurp|Java VM|DotBot|LiteFinder|Yeti|Rambler|Scrubby|Baiduspider|accoona/i)
  end
  
  def updateFilters(myfilter)
    #Delete blank values
    myfilter.delete_if{|k,v|v.blank?}
    #Fix price, because it's stored as int in db
    myfilter[:price_max] = myfilter[:price_max].to_i*100 if myfilter[:price_max]
    myfilter[:price_min] = myfilter[:price_min].to_i*100 if myfilter[:price_min]
    myfilter[:itemwidth_max] = myfilter[:itemwidth_max].to_i*100 if myfilter[:itemwidth_max]
    myfilter[:itemwidth_min] = myfilter[:itemwidth_min].to_i*100 if myfilter[:itemwidth_min]
    myfilter[:session_id] = id
    myfilter = handle_false_booleans(myfilter)
    self.filter = true
    @oldfeatures = features
    @features = $featuremodel.new(myfilter)
  end
  
  def copyfeatures
    @features = $featuremodel.new(features.attributes)
  end
 
  def clusters
    #Find clusters that match filtering query
    if !expandedFiltering? && searches.last
      #Search is narrowed, so use current products to begin with
      clusters = searches.last.clusters
    else
      #Search is expanded, so use all products to begin with
      clusters = findAllCachedClusters(0)
      clusters.delete_if{|c| c.isEmpty} #This is broken for test profile in Rails 2.3.5
      #clusters = clusters.map{|c| c unless c.isEmpty}.compact
    end
    clusters
  end
  
  def commitFilters(search_id)
    update_attribute('filter',true)
    @features.search_id = search_id
    @features.save
  end
  
  def rollback
    @features = @oldfeatures if @oldfeatures
  end
  
  def defaultFeatures(mode)
    update_attribute('filter', true)
    features.update_attributes($featuremodel.find($DefaultUses[mode]).attributes.delete_if{|k,v| k=='id' || k=='created_at' || k=='updated_at' || k=='session_id'})
  end
        
  def features
    #Return row of Product's Feature table
    unless @features
      if Session.current.search.nil?
        debugger
      else
        @features = $featuremodel.find(:last, :conditions => ['session_id = ? and search_id = ?', id, Session.current.search.id])
        @features = $featuremodel.new({'session_id' => id, 'search_id' => Session.current.search.id}) if @features.nil?
      end
    end
    @features
  end
  
  private
  
  def handle_false_booleans(myfilter)
    $model::BinaryFeaturesF.each do |f|
      myfilter.delete(f.intern) if myfilter[f.intern] == '0' && features.send(f.intern) != true
    end
    myfilter
  end
  
  def expandedFiltering?
    features.attributes.keys.each do |key|
      if key.index(/(.+)_min/)
        fname = Regexp.last_match[1]
        max = fname+'_max'
        maxv = @oldfeatures.send(max.intern)  
        if !maxv.nil? # If the oldsession max value is not nil then calculate newrange
          oldrange = maxv - @oldfeatures.send(key.intern)
          newrange = features.attributes[max] - features.attributes[key]
          if newrange > oldrange
            return true #Continuous
          end
        end
      elsif !$model::BinaryFeaturesF.empty? && key.index(/#{$model::BinaryFeaturesF.join('|')}/)
        if features.attributes[key] == false
          #Only works for one item submitted at a time
          features.send((key+'=').intern, nil)
          return true #Binary
        end
      elsif !$model::CategoricalFeaturesF.empty? && key.index(/#{$model::CategoricalFeaturesF.join('|')}/)
        oldv = @oldfeatures.send(key.intern)
        if oldv
          new_a = features.attributes[key].nil? ? [] : features.attributes[key].split('*').uniq
          old_a = oldv.nil? ? [] : oldv.split('*').uniq
          return true if new_a.length == 0 && old_a.length > 0
          return true if old_a.length > 0 && new_a.length > old_a.length
        end
      end
    end
    false
  end
end
