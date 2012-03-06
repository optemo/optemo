module Ranges
  attr_writer :min, :max, :count
  
  def initialize (min, max, count)
    @min = min
    @max = max
    @count = count  
  end  
  
	def self.getRange(feat, num_buckets)
	  discretized = Session.search.solr_cached.facet(feat.to_sym).rows
	  if (!discretized.empty?)
	    min_all = CachingMemcached.cache_lookup("Min#{Session.search.keyword_search}#{feat}") {discretized.first.value}
	    max_all = CachingMemcached.cache_lookup("Max#{Session.search.keyword_search}#{feat}") {discretized.last.value}
	    min = discretized.first.value
	    max = discretized.last.value
	    if feat=="price"
	      p_min = discretized.first 
	      p_max = discretized.last
	     # self.price_ranges(p_min, p_max)
	      grouped_data = Kmeans.compute(7, Session.search.solr_cached.facet(feat.to_sym).rows.map{|r| [r.value]*r.count}.flatten)
      else    
	      grouped_data = Kmeans.compute(7, Session.search.solr_cached.facet(feat.to_sym).rows.map{|r| [r.value]*r.count}.flatten)
	    end  
      #puts feat
      debugger if grouped_data.nil?
      #grouped_data.each do  |g|
      #  puts "#{g.min}-#{g.max} (#{g.count.to_s})"
      #end         
      rs = []   
	    grouped_data.map do |g| 
	      r = {}
	      r["min"] = g.min 
	      r["max"]=g.max 
	      r["count"]=g.count
	      rs << r
	    end    
	  else
	    rs = []
	  end
	  rs
	end

  def self.price_range(min, max)
    ranges = [0,50,100, 200, 300, 500, 1000, 2000, 3000, 5000, 1000000]
    s = ranges.first
    e = ranges.last
    ranges.each do |r| 
      s = r if r>min
      e = r if r>max
    end
    count = 0
    #data.map{|d| count++ if }
  end
    
  def self.getRanges(feat, num_ranges)
    dist = self.getDist(feat, num_ranges*3)
  debugger
    dist
  end  

end	
