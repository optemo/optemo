module Ranges
  
	def self.getRange(feat, num)
	  discretized = Session.search.solr_cached.facet(feat.to_sym).rows
	  rs = []
	  if (!discretized.empty?)
	    min_all = CachingMemcached.cache_lookup("Min#{Session.search.keyword_search}#{feat}") {discretized.first.value}
	    max_all = CachingMemcached.cache_lookup("Max#{Session.search.keyword_search}#{feat}") {discretized.last.value}
	    if feat=="price"
	      p_min = discretized.first.value
	      p_max = discretized.last.value
	      rs  = self.price_ranges(p_min, p_max)
      else    
	      grouped_data = Kmeans.compute(num, Session.search.solr_cached.facet(feat.to_sym).rows.map{|r| [r.value]*r.count}.flatten)
	      debugger if grouped_data.nil?
        #grouped_data.each do  |g|
        #  puts "#{g.min}-#{g.max} (#{g.count.to_s})"
        #end    
  	    grouped_data.each do |g| 
  	      rs << {:min => g.min, :max => g.max} 
  	    end
	    end 
    end   
      #puts feat
	  rs
	end
	
	def self.count(feat, min, max)
	  a = Session.search.solr_cached.facet(feat.to_sym).rows.map{|r| [r.value]*r.count}.flatten
	  a.map{|p| p if (p<max && p>=min)}.compact.size  
	end
	  
  def self.cacherange(feat, num) 
     Rails.cache.fetch("Ranges#{feat}#{num}") do
       self.getRange(feat, num)
     end
   end

 def self.price_ranges(min, max)
   prs = [0,50,100, 200, 300, 500, 1000, 2000, 3000, 5000, 1000000]
   rs = []
   prs.each_with_index do |pr, ind| 
     if rs.empty? && pr>min 
       rs << {:min => prs[ind-1], :max => pr}
     elsif !rs.empty?
       rs << {:min => prs[ind-1], :max => pr}
     end 
   end
   rs
 end

end	
