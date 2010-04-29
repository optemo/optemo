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
  
  def self.isCrawler?(str)
    str.match(/Google|msnbot|Rambler|Yahoo|AbachoBOT|accoona|AcioRobot|ASPSeek|CocoCrawler|Dumbot|FAST-WebCrawler|GeonaBot|Gigabot|Lycos|MSRBOT|Scooter|AltaVista|IDBot|eStyle|ScrubbyBloglines subscriber|Dumbot|Sosoimagespider|QihooBot|FAST-WebCrawler|Superdownloads Spiderman|LinkWalker|msnbot|ASPSeek|WebAlta Crawler|Lycos|FeedFetcher-Google|Yahoo|YoudaoBot|AdsBot-Google|Googlebot|Scooter|Gigabot|Charlotte|eStyle|AcioRobot|GeonaBot|msnbot-media|Baidu|CocoCrawler|Google|Charlotte t|Yahoo! Slurp China|Sogou web spider|YodaoBot|MSRBOT|AbachoBOT|Sogou head spider|AltaVista|IDBot|Sosospider|Yahoo! Slurp|Java VM|DotBot|LiteFinder|Yeti|Rambler|Scrubby|Baiduspider|accoona/i)
  end
  
  def updateFilters(myfilter)
    #Delete blank values
    myfilter.delete_if{|k,v|v.blank?}
    #Fix price, because it's stored as int in db
    myfilter[:session_id] = id
    #Handle false booleans
    $config["BinaryFeaturesF"].each do |f|
      myfilter.delete(f.intern) if myfilter[f.intern] == '0' && features[f.intern] != true
    end
    filter = true
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
        
  #def features
  #  #Return row of Product's Feature table
  #  unless @features
  #    if Session.current.search.nil?
  #      debugger
  #    else
  #      @features = $featuremodel.find(:last, :conditions => ['session_id = ? and search_id = ?', id, Session.current.search.id])
  #      @features = $featuremodel.new({'session_id' => id, 'search_id' => Session.current.search.id}) if @features.nil?
  #    end
  #  end
  #  @features
  #end
  
  private
  
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
