module Ranges
  
	def self.getRange(feat, num)
	  discretized = Session.search.solr_search({mybins: [], mycats: [], myconts: []}).facet(feat.to_sym).rows
	  rs = []
	  if (!discretized.empty?)
	    if feat=="saleprice"
	      p_min = discretized.map{|d| d.value}.min
	      p_max = discretized.map{|d| d.value}.max
	      rs  = self.price_ranges(p_min, p_max)
      else    
	      grouped_data = Kmeans.compute(num, discretized.map{|r| [r.value]*r.count}.flatten)
	      #debugger
	      debugger if grouped_data.nil?
        #grouped_data.each do  |g|
        #  puts "#{g.min}-#{g.max} (#{g.count.to_s})"
        #end    
  	    grouped_data.each do |g| 
  	      rs << {:min => g.min, :max => g.max} 
  	    end
	    end 
    end
    rs
  end
  
  def self.count(feat, min, max)
    if (feat == "saleprice")
      Session.search.solr_cached.facet(feat.to_sym).rows.select{|p| p.value == min||(p.value<max && p.value>=min) }.inject(0){|sum,elem|sum+elem.count}
    else
      Session.search.solr_cached.facet(feat.to_sym).rows.select{|p| p.value<=max && p.value>=min }.inject(0){|sum,elem|sum+elem.count}
    end
  end

  def self.cacherange(feat, num) 
     Rails.cache.fetch("Ranges#{Session.product_type}#{feat}#{num}") do
       self.getRange(feat, num)
     end
  end

 def self.price_ranges(min, max)
   prs = [0, 50, 100, 150, 200, 300, 500, 1000, 2000, 3000, 5000, 1000000]
   rs = []
   prs.each_with_index do |pr, ind|
     if max<prs.last
       if rs.empty? && pr>min 
         rs << {:min => prs[ind-1], :max => pr}
       elsif !rs.empty? && max>pr 
         rs << {:min => prs[ind-1], :max => pr}
         if max>=pr && max<prs[ind+1]
           rs << {:min => pr, :max => prs[ind+1]}
         end 
       end
    end
   end
   rs
 end

end	