class Search < ActiveRecord::Base
  belongs_to :session
  attr_writer :userdataconts, :userdatacats, :userdatabins
  
  def userdataconts
      @userdataconts ||= Userdatacont.find_all_by_search_id(id)
  end
  
  def userdatacats
      @userdatacats ||= Userdatacat.find_all_by_search_id(id)
  end
  
  def userdatabins
      @userdatabins ||= Userdatabin.find_all_by_search_id(id)
  end
  
  ## Computes distributions (arrays of normalized product counts) for all continuous features 
  def distribution(feat)
       dist = Array.new(21,0)
       min = CachingMemcached.minSpec(feat)
       max = CachingMemcached.maxSpec(feat)
       return [] if max.nil? || min.nil?
       stepsize = (max-min) / dist.length + 0.000001 #Offset prevents overflow of 10 into dist array
       acceptedNodes.each do |n|
         i = ((ContSpec.cached(n.product_id,feat).value - min) / stepsize).to_i
#         i = ((ContSpec.featurecache(feat, n.product_id).value - min) / stepsize).to_i
         dist[i] += 1 if i < dist.length
       end  
       round2Decim(normalize(dist))
  end
  
  def acceptedNodes
    @acceptedNodes ||= clusters.map{|c| c.nodes}.flatten 
  end
  
  #Range of product offerings
  def ranges(featureName)
     @sRange ||= {}
     if @sRange[featureName].nil?
       min = clusters.map{|c|c.ranges(featureName)[0]}.compact.sort[0]
       max = clusters.map{|c|c.ranges(featureName)[1]}.compact.sort[-1] 
       @sRange[featureName] = [min, max]
     end
     @sRange[featureName]  
  end
  
  def indicator(featureName)
    indic = false
    values = clusters.map{|c| c.indicator(featureName)}
    if values.index(false).nil?
      indic = true
    end  
    indic
  end
  
  def relativeDescriptions
    return if clusters.empty?
    @reldescs ||= []
    if @reldescs.empty?
      feats = {}
      $Continuous["filter"].each do |f|
        norm = CachingMemcached.maxSpec(f) - CachingMemcached.minSpec(f)
        norm = 1 if norm == 0
        feats[f] = clusters.map{ |c| c.representative}.compact.map {|c| c[f].to_f/norm } 
      end
      cluster_count.times do |i|
        dist = {}
        $Continuous["filter"].each do |f|
          if feats[f].min == feats[f][i]
            #This is the lowest feature
            distance = feats[f].sort[1] - feats[f][i]
            dist[f] = distance unless distance == 0 && feats[f].sort[2] == feats[f][i] #Remove ties
          elsif feats[f].max == feats[f][i]
            #This is the highest feature
            distance = feats[f][i] - feats[f].sort[-2]
            dist[f] = distance unless distance == 0 && feats[f].sort[-3] == feats[f][i] #Remove ties
          #elsif feats[f].sort[4] == feats[f][i]
          #  #This is an average feature
          #  dist[f] = ([feats[f].sort[4]-feats[f].sort[3],feats[f].sort[5]-feats[f].sort[4]].min) - 1
          #  dist[f] = distance unless distance == -1 #Remove ties
          end
        end if cluster_count > 1
        n = dist.count
        d = []
        dist.sort{|a,b| b[1] <=> a[1]}[0..1].each do |f,v|
          dir = feats[f].min == feats[f][i] ? "lower" : "higher"
          #dir = feats[f].min == feats[f][i] ? "lower" : feats[f].max == feats[f][i] ? "higher" : "avg"
          d << dir+f
        end
        #Add binary labels
        #d.unshift "Waterproof" if clusters[i].waterproof && layer == 1
        #d.unshift "SLR" if clusters[i].slr && layer == 1
        if d.empty?
          @reldescs << ["avg"]
        else
          @reldescs << d
        end
        #@descs[-1] = @descs.last + " (#{n})"
      end
    end
    @reldescs
  end
    
  def boostexterClusterDescriptions
    ActiveRecord::Base.include_root_in_json = false # json conversion is used below, and this makes it cleaner
    if @returned_taglines 
      return @returned_taglines
    else
      # This looks quite a bit like code from CachingMemcached, but it's not of the standard Rails.cache.fetch call with a small block, so it belongs here instead.
      unless ENV['RAILS_ENV'] == 'development'
        cluster_ids = clusters.map{|c| c.id}.join("-")
        @returned_taglines = Rails.cache.read("#{$product_type}Taglines#{Session.current.version}#{cluster_ids}#{Session.current.features.to_json(:except => [ :id, :created_at, :updated_at, :session_id, :search_id ]).hash}")
        return @returned_taglines unless @returned_taglines.nil?
      end
      @returned_taglines = []
    end

    weighted_averages = {}
    catlabel = {}
    return if clusters.empty?
    descriptions = Array.new
    clusters.each do |c|
      weighted_averages[c.id] = {}
      catlabel[c.id] = []
      current_nodes = c.nodes
      product_ids = current_nodes.map {|n| n.product_id }
      product_query_string = "id IN (" + product_ids.join(" OR ") + ")"
      
      rules = BoostexterRule.bycluster(c.id)
      unless product_ids.empty?
        @products = Product.cached(product_ids).index_by(&:id)        
        rules.each do |r|
          # This check will not work in future, but will work for now. There will be a type field in the YAML representation instead.
          brules = YAML.load(r.yaml_repr)
          if r.rule_type == "S"
            catlabel[c.id] << r.fieldname + ": " + brules["sgram"] if brules["direction"] == 1
          else
            unpacked_weighted_intervals = brules.map {|i| [i["interval"], i["weight"]] unless i.class == Array}
            next if unpacked_weighted_intervals.compact.empty?
            z = 0
            weighted_average = 0
            product_ids.each do |id| 
              product = @products[id]
              feature_value = product.send(r.fieldname)
              next unless feature_value
              weight = find_weight_for_value(unpacked_weighted_intervals, feature_value)
              weighted_average += weight * feature_value
              z += weight
            end
            next if z == 0 # Loop back to the beginning; do not add this field name for this cluster.
            weighted_average /= z
            weighted_averages[c.id][r.fieldname] = weighted_average
          end
        end
      end
    end
    weighted_averages.each do |cluster_id,featurehash|
      current_cluster_tagline = []
      featurehash.each do |featurename,weighted_average|
        quartiles = compute_quartile(featurename)
        if weighted_average < quartiles[0].to_f # This is low for the given feature
          current_cluster_tagline.push("lower#{featurename}")
        elsif weighted_average > quartiles[1].to_f # This is high for the given feature
          current_cluster_tagline.push("higher#{featurename}")
        else # Inclusion. It's between 25% and 75%
          # Do nothing? Averages are not included for now, take out the comment on the next line to add
          # current_cluster_tagline.push("avg#{featurename}")
        end
        break if current_cluster_tagline.length == 2 # Limit to 2 taglines per cluster (this is due to a space limitation in the UI)
      end
      @returned_taglines.push(current_cluster_tagline+catlabel[cluster_id])
    end
    @returned_taglines = @returned_taglines.map{|line_array| line_array.empty? ? ["average"] : line_array}
    unless ENV['RAILS_ENV'] == 'development'
      cluster_ids = clusters.map{|c| c.id}.join("-")
      Rails.cache.write("#{$product_type}Taglines#{Session.current.version}#{cluster_ids}#{Session.current.features.to_json(:except => [ :id, :created_at, :updated_at, :session_id, :search_id ]).hash}", @returned_taglines)
    end
    return @returned_taglines # [ ["avgdisplaysize", "highminimumfocallength"],["avgprice", ""] , ...] 
  end

def compute_quartile(featurename)
  # This can be sped up by the following: Instead of fetching p.maximumresolution, then p.displaysize, etc.,
  # just do a single query for p. If there are multiple features to fetch, the rest of the query is guaranteed to be identical
  # and doing activerecord caching will help
  filter_query_thing = ""
  filter_query_thing = Cluster.filterquery(Session.current, 'n.') + " AND " if Session.current.filter && !Cluster.filterquery(Session.current, 'n.').blank?
  cluster_ids = clusters.map{|c| c.id}.join(", ")
  product_count = ActiveRecord::Base.connection.select_one("select count(distinct(p.id)) from products p, nodes n, clusters cc WHERE p.#{featurename} is not NULL AND #{filter_query_thing} n.product_id = p.id AND cc.id = n.cluster_id AND cc.id IN (#{cluster_ids})")
  product_count = product_count["count(distinct(p.id))"].to_i
  q25offset = (product_count / 4.0).floor
  q75offset = ((product_count * 3) / 4.0).floor
  # Although we have @products, the database *should* be substantially faster at sorting them for each quartile computation.
  # However, we might be limited by the network connection here instead. For database connections on localhost, probably not, so leave as-is.
  q25 = ActiveRecord::Base.connection.select_one("select p.#{featurename} from products p, nodes n, clusters cc WHERE p.#{featurename} is not NULL AND #{filter_query_thing} n.product_id = p.id AND cc.id = n.cluster_id AND cc.id IN (#{cluster_ids}) ORDER BY #{featurename} LIMIT 1 OFFSET #{q25offset}")
  q75 = ActiveRecord::Base.connection.select_one("select p.#{featurename} from products p, nodes n, clusters cc WHERE p.#{featurename} is not NULL AND #{filter_query_thing} n.product_id = p.id AND cc.id = n.cluster_id AND cc.id IN (#{cluster_ids}) ORDER BY #{featurename} LIMIT 1 OFFSET #{q75offset}")
  [q25[featurename], q75[featurename]]
end
  
  def clusterDescription(clusterNumber)
    return if clusters.empty?
    clusterDs = Array.new 
    des = []
    slr=0
      $Binary["filter"].each do |f|
        if clusters[clusterNumber].indicator(f)
          (f=='slr' && indicator("slr"))? slr = 1 : slr =0
          des<< f if $config["DescFeatures"].include?(f) 
        end
      end
      
      $Continuous["desc"].each do |f|
        if !(f == "opticalzoom" && slr == 1)
              cRanges = clusters[clusterNumber].ranges(f)
              if (cRanges[1] < CachingMemcached.lowSpec(f))
                 clusterDs << {'desc' => "low_"+f, 'stat' => 0}  
              elsif (cRanges[0] > CachingMemcached.highSpec(f))
                 clusterDs <<  {'desc' => "high_"+f, 'stat' => 2}  
              elsif ((cRanges[0] >= CachingMemcached.lowSpec(f)) && (cRanges[1] <= CachingMemcached.highSpec(f))) 
                  clusterDs <<  {'desc' => "avg_"+f, 'stat' => 1}
              end 
        end   
      end     
      
    clusterDs.sort!{|a,b| b['stat'] <=> a['stat']}
    clusterDs = clusterDs[0..1] if clusterDs.size > 2
    clusterDs[0] = {'desc' => "average", 'stat' => 1} if clusterDs.blank?
    des << clusterDs.map{|d| d['desc']};
  end
  
  def searchDescription
    des = []
    $Continuous["desc"].each do |f|
      searchR = ranges(f)
      return ['Empty'] if searchR[0].nil? || searchR[1].nil?
      if (searchR[1] <= CachingMemcached.lowSpec(f))
           des <<  "low_#{f}"
      elsif (searchR[0] >= CachingMemcached.highSpec(f))
           des <<  "high_#{f}"
      end
    end  
    des[0..3]
  end

    
  def minimum(feature)
    feature = feature + "_min"
    min = clusters[0].send(feature)
    for i in 1..cluster_count-1
      min = clusters[i].send(feature) if clusters[i].send(feature) < min
    end
    min
  end
  
  def maximum(feature)
    feature = feature + "_max"
    max = clusters[0].send(feature)
    for i in 1..cluster_count-1
      max = clusters[i].send(feature) if clusters[i].send(feature) > max
    end
    max
  end
    
  def result_count
    clusters.map{|c| c.size}.sum
  end
  
  def clusters= (clusters)
    @clusters = clusters
  end
  
  def clusters
    if @clusters.nil?
      @clusters = []
      cluster_count.times do |i|
        cluster_id = send(:"c#{i}")
        if cluster_id.index('+')
          cluster_id.gsub(/[^(\d|+)]/,'') #Clean URL input
          #Merged Cluster
          c = MergedCluster.fromIDs(cluster_id.split('+'))
        else
          #Single, normal Cluster
          c = Cluster.cached(cluster_id)
        end
        #Remove empty clusters
        if c.nil? || c.isEmpty
          self.cluster_count -= 1
        else
          @clusters << c 
        end
      end
    end
    @clusters
  end
  
  #The clusters argument can either be an array of cluster ids or an array of cluster objects if they have already been initialized
  def self.createFromClusters(clusters)
    ns = {}
    mycluster = "c0"
    ns['cluster_count'] = clusters.length
    clusters.each do |p|
      ns[mycluster] = case p.class.name
        when "String" then p
        when "Fixnum" then p.to_s
        when "Cluster" then p.id.to_s
      end
      mycluster.next!
    end
    ns['session_id'] = Session.current.id
    ns['searchpids'] = Session.current.keywordpids
    ns['searchterm'] = Session.current.keyword
    s = new(ns)
    s.session = Session.current
    unless clusters.nil? || clusters.empty? || clusters.first.class == String || clusters.first.class == Fixnum
        s.clusters = clusters.sort{|a,b| (a.size>1 ? -1 : 1) <=> (b.size>1 ? -1 : 1)}
    end
#    s.fillDisplay
    #I think these are deprecated
    #s.parent_id = s.clusters.map{|c| c.parent_id}.sort[0]
    #s.layer = s.clusters.map{|c| c.layer}.sort[0]
    s
  end
  
  def self.createFromFilters(myfilter)
    #Delete blank values
    myfilter.delete_if{|k,v|v.blank?}
    #Fix price, because it's stored as int in db
    myfilter[:session_id] = Session.current.id
    #Handle false booleans
    $Binary["filter"].each do |f|
      dobj = Session.current.search.userdatabins.select{|d|d.name == f}.first
      myfilter.delete(f.intern) if myfilter[f.intern] == '0' && (dobj.nil? || dobj.value != true)
    end
    
    s = new({:session_id => Session.current.id, :searchpids => Session.current.keywordpids, :searchterm => Session.current.keyword})
    
    #seperate myfilter into various parts
    s.userdataconts = []
    s.userdatabins = []
    s.userdatacats = []
    
    myfilter.each_pair {|k,v|
      if k.index(/(.+)_min/)
        fname = Regexp.last_match[1]
        max = fname+'_max'
        s.userdataconts << Userdatacont.new({:name => fname, :min => v, :max => myfilter[max]})
      elsif $Binary["filter"].index(k)
        s.userdatabins << Userdatabin.new({:name => k, :value => v})
      elsif $Categorical["filter"].index(k)
        s.userdatacats << Userdatacat.new({:name => k, :value => v})
      end
    }
    
    #Find clusters that match filtering query
    if !s.expandedFiltering? && Session.current.searches.last
      #Search is narrowed, so use current products to begin with
      s.clusters = Session.current.searches.last.clusters
    else
      #Search is expanded, so use all products to begin with
      s.clusters = Cluster.byparent(0).delete_if{|c| c.isEmpty} #This is broken for test profile in Rails 2.3.5
      #clusters = clusters.map{|c| c unless c.isEmpty}.compact
    end
    s
  end
  
  def self.createFromClustersAndCommit(clusters)
    s = createFromClusters(clusters)
    s.save
    #Duplicate the features
    os = Session.current.search
    if os
      (os.userdataconts+os.userdatacats+os.userdatabins).each do |d|
        nd = d.class.new(d.attributes)
        nd.search_id = s.id
        nd.save
      end
    end
    s
  end
  
  def self.createFromKeywordSearch(nodes)
    if !(nodes.nil?) && nodes.length < 50 # Guess; this should be profiled later.
      clusters = nodes.map { |node| Cluster.cached(node.cluster_id) }.uniq

      while clusters.length > $NumGroups
        clusters = clusters.map do |cluster|
          if cluster.parent_id != 0 # It's possible to have clusters at different layers, so we need to check for this.
            Cluster.cached(cluster.parent_id)
          else
            cluster
          end
        end
        clusters = clusters.uniq
      end
    else
      clusters = nodes.map{|n|n.cluster_id}.uniq
    end
    createFromClustersAndCommit(clusters)
  end
  
  def self.createInitialClusters
    #Remove search terms
    Session.current.keywordpids = nil
    Session.current.keyword = nil
    Session.current.filter = false #Maybe this should be saved
    Session.current.search = self.createFromClustersAndCommit(Cluster.byparent(0))
  end
  
  def commitfilters
    cluster_count = clusters.length
    mycluster = "c0="
    clusters.each do |p|
      send(mycluster.intern, p.id.to_s)
      mycluster.next!
    end
    save
    
    #Save user filters
    (userdataconts+userdatabins+userdatacats).each do |d|
      d.search_id = id
      d.save
    end
  end
  
  def to_s
    clusters.map{|c|c.id}.join('-')
  end
  
  def fillDisplay
    clusters #instantiate clusters to update cluster_count
    if false #cluster_count < $NumGroups && cluster_count > 0
      if clusters.map{|c| c.size}.sum >= 9
        myclusters = splitClusters(clusters)
      else
        #Display only the deep children
        myclusters = clusters.map{|c| c.deepChildren}.flatten
      end
    else
      myclusters = clusters
    end
    updateClusters(myclusters)
  end
  
  def expandedFiltering?
    #Continuous feature
    userdataconts.each do |f|
      old = Session.current.search.userdataconts.find_by_name(f.name) 
      if old # If the oldsession max value is not nil then calculate newrange
        oldrange = old.max - old.min
        newrange = f.max - f.min
        if newrange > oldrange
          return true #Continuous
        end
      end
    end
    #Binary Feature
    userdatabins.each do |f|
      if f.value == false
        #Only works for one item submitted at a time
        userdatabins.delete(f)
        return true #Binary
      end
    end
    #Categorical Feature
    userdatacats.each do |f|
      old = Session.current.search.userdatacats.find_all_by_name(f.name) 
      unless old.empty?
        newf = userdatacats.find_all_by_name(f.name)
        return true if newf.length == 0 && old.length > 0
        return true if old.length > 0 && newf.length > old.length
      end
    end
    false
  end
  
  private
  
  def updateClusters(myclusters)
    self.cluster_count = myclusters.length
    myc = "c0="
    cluster_count.times do |i|
      send(myc.intern,myclusters[i].id)
      myc.next!
    end
    @clusters = myclusters
  end
  
  def splitClusters(myclusters)
    while myclusters.length != $NumGroups
      myclusters.sort! {|a,b| b.size <=> a.size}
      myclusters = split(myclusters.shift.children) + myclusters
    end
    myclusters.sort! {|a,b| b.size <=> a.size}
  end  
  
  def split(children)
    return children if children.length == 1
    children.sort! {|a,b| b.size <=> a.size}
    [children.shift, MergedCluster.new(children)]
  end
  
  def normalize(a)
    total = a.max
    if total==0 
      a  
    else    
      a.map{|i| i.to_f/total}
    end  
  end
  
  def round2Decim(a)
    a.map{|n| (n*1000).round.to_f/1000}
  end  

  def find_weight_for_value(unpacked_weighted_intervals, feature_value)
    weight = 0
    unpacked_weighted_intervals.each do |uwi| 
      if (uwi[0][0] < feature_value && uwi[0][1] >= feature_value)
        weight = uwi[1]
        break
      end
    end
    weight
  end
end

