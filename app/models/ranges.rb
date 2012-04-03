module Ranges
  
	def self.getRange(feat, num)
	  discretized = self.getRows(feat) 
	  rs = []
	  if (!discretized.empty?)
	    if feat=="saleprice"
	      rs  = self.price_ranges(discretized)
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
  
  def self.getRows(feat)
     @rows ||= Session.search.solr_search({mybins: [], mycats: [], myconts: []})
     @rows.facet(feat.to_sym).rows
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

  def self.price_ranges(discretized)
    min = discretized.map{|d| d.value}.min
    max = discretized.map{|d| d.value}.max
    s = self.count(saleprice, min, max) # total count of prods with this feature
    prs = [0, 50, 100, 150, 200, 300, 500, 1000, 2000, 3000, 5000, 1000000]
    gprs = [0, 10, 25, 50]
    prs.each_with_index do |pr, ind|
      if max<prs.last
        if rs.empty? && pr>min
          if self.count(saleprice, prs[ind-1], pr) > s/4
            
          else
            rs << {:min => prs[ind-1], :max => pr}
          end      
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
