module Ranges
  NUM_RANGES = 6
  def self.getRange(feats, cats, num)
    discretized = Session.search.solr_search({mybins: [], mycats: cats, myconts: []})
    ranges = {}
    feats.each do |feat|
      dis = discretized.facet(feat.to_sym)
      unless dis.nil? 
        dis = dis.rows
        rs = []
        unless dis.empty?
          if feat == "saleprice" or feat == "pricePlusEHF"
            rs = self.price_ranges(dis)
          else
            grouped_data = Kmeans.compute(num, dis.map{|r| [r.value]*r.count}.flatten)
            unless grouped_data.nil?
              grouped_data.each do |g|
                rs.push g.min..g.max
              end
            end
          end
        end
        ranges[feat.to_sym] = rs
      end
    end
    ranges
  end
  
  def self.modifyRanges(selected_ranges, ranges, fname = nil)
    epsilon = fname == 'saleprice' || fname == 'pricePlusEHF' ? 0 :  0.1
    selected_ranges.sort!{|a,b| a.min <=> b.min}
    #Ranges are expected to be ordered
    modified_ranges = []
    # |****| selected_ranges
    # |----| ranges
    ranges.each do |r|
      # |***| |----|
      while !selected_ranges.empty? && selected_ranges.first.max < r.min
        modified_ranges << selected_ranges.shift
      end
      # |****|
      #   |----|
      if !selected_ranges.empty? && selected_ranges.first.max < r.max
        current_selection = selected_ranges.shift
        if current_selection.min > r.min
          #     |**|
          #   |-----|
          if modified_ranges.empty?
            modified_ranges.push r.min..(current_selection.min-epsilon)
          elsif current_selection.min > modified_ranges.last.max+epsilon
            modified_ranges.push [r.min,modified_ranges.last.max+epsilon].max..(current_selection.min-epsilon)
          end
        end
        modified_ranges.push current_selection
        if selected_ranges.empty?
          modified_ranges.push (current_selection.max+epsilon)..r.max
        elsif selected_ranges.first.min > current_selection.max+epsilon
          modified_ranges.push (current_selection.max+epsilon)..[r.max,selected_ranges.first.min-epsilon].min
        end
        #      |**| |**|
        #    |------------|
        redo if !selected_ranges.empty? && selected_ranges.first.max <= (r.max - epsilon)
      elsif !selected_ranges.empty? && selected_ranges.first.min <= r.max
        #    |******|
        # |-----|
        if selected_ranges.first.min > r.min
          modified_ranges.push r.min..(selected_ranges.first.min-epsilon)
        else
          # |*********|
          #   |----|   
          # Do nothing - wait until next loop
        end
      #        |****|
      # |----|
      else
        modified_ranges << r
      end
    end
    #        |****|
    # |----|
    round_factor = fname == 'saleprice' || fname == 'pricePlusEHF' ? 2 : 1
    modified_ranges.map!{|r| FloatRange.new(r.min.round(round_factor),r.max.round(round_factor),fname)}
    modified_ranges + selected_ranges
  end
  
  def self.count(feat, min, max)
    if feat == "saleprice" or feat == "pricePlusEHF"
      Session.search.solr_cached.facet(feat.to_sym).rows.select{|p| p.value == min||(p.value<max && p.value>=min) }.inject(0){|sum,elem|sum+elem.count}
    else
      Session.search.solr_cached.facet(feat.to_sym).rows.select{|p| p.value<=max && p.value>=min }.inject(0){|sum,elem|sum+elem.count}
    end
  end
  
  def self.cache
    #Pick ranges for subcategory if only 1 subcategory is selected
    product_type_cat = Session.subcategory.length == 1 ? Session.subcategory : []
    product_type = product_type_cat.empty? ? Session.product_type : product_type_cat.first.value
    range_filters = Session.range_filters
    Rails.cache.fetch("Ranges#{product_type}#{NUM_RANGES}#{range_filters.join}") do
      self.getRange(range_filters, product_type_cat, NUM_RANGES)
    end
  end

  def self.price_ranges(discretized)
    min = discretized.first.value
    max = discretized.last.value
    rs = []
    prs = [0, 50, 100, 150, 200, 300, 500, 1000, 2000, 3000, 5000, 10000, 20000].map{|x|x.to_f}
    gprs = [0, 10, 25, 50, 100, 150, 200, 250, 300, 400, 500, 750, 1000, 2000, 3000, 4000, 5000, 7500, 10000, 20000].map{|x|x.to_f}
    prs.each_with_index do |pr, ind|
      if max < prs.last
        if rs.empty? && pr > min
          rs.push prs[ind-1]..pr
        elsif !rs.empty? && max > pr
          rs.push prs[ind-1]..pr
          if max >= pr && max < prs[ind+1]
            rs.push pr..prs[ind+1]
          end 
        end
      end
    end
    rs
  end

end	
