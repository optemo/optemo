module Ranges
  NUM_RANGES = 6
	def self.getRange(feats, num)
	  discretized = Session.search.solr_search({mybins: [], mycats: [], myconts: []})

	  ranges = {}  
    feats.each do |feat| 
      dis = discretized.facet(feat.to_sym)
      unless dis.nil? 
        dis = dis.rows
	      rs = []
	      if (!dis.empty?)
	        if feat == "saleprice" or feat == "pricePlusEHF"
	          rs  = self.price_ranges(dis)
          else    
	          grouped_data = Kmeans.compute(num, dis.map{|r| [r.value]*r.count}.flatten)
	          next if grouped_data.nil?
  	        grouped_data.each do |g| 
  	          rs << {:min => g.min, :max => g.max} 
  	        end
	        end 
        end
        ranges[feat.to_sym] = rs
      end  
    end
    ranges
  end
    
  def self.count(feat, min, max)
    if feat == "saleprice" or feat == "pricePlusEHF"
      Session.search.solr_cached.facet(feat.to_sym).rows.select{|p| p.value == min||(p.value<max && p.value>=min) }.inject(0){|sum,elem|sum+elem.count}
    else
      Session.search.solr_cached.facet(feat.to_sym).rows.select{|p| p.value<=max && p.value>=min }.inject(0){|sum,elem|sum+elem.count}
    end
  end

  def self.cache
    Rails.cache.fetch("Ranges#{Session.product_type}#{NUM_RANGES}#{Session.range_filters.join}") do
      self.getRange(Session.range_filters, NUM_RANGES)
    end
  end

  def self.price_ranges(discretized)
    min = discretized.first.value
    max = discretized.last.value
    rs = []
    prs = [0, 50, 100, 150, 200, 300, 500, 1000, 2000, 3000, 5000, 10000, 20000].map{|x|x.to_f}
    gprs = [0, 10, 25, 50, 100, 150, 200, 250, 300, 400, 500, 750, 1000, 2000, 3000, 4000, 5000, 7500, 10000, 20000].map{|x|x.to_f}
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
