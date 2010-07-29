class BoostexterRule < ActiveRecord::Base
  # This is a good idea, but right now the boostexter_combined_rules only works for cameras (March 23). Update this in future.
  def self.bycluster(cluster_id)
    CachingMemcached.cache_lookup("BoostexterRules#{cluster_id}") do
      find(:all, :select => "fieldname, yaml_repr", :order => "weight DESC", :conditions => {"cluster_id" => cluster_id})
    end
  end
  
  def self.clusterLabels(clusters)
    #return [["average"]]*clusters.size
    return if clusters.empty?
    cluster_ids = clusters.map(&:id).join(",")
    selected_features = (Session.current.search.userdataconts.map{|c| c.name+c.min.to_s+c.max.to_s}+Session.current.search.userdatabins.map{|c| c.name+c.value.to_s}+Session.current.search.userdatacats.map{|c| c.name+c.value}).hash
    CachingMemcached.cache_lookup("#{$product_type}Taglines#{cluster_ids}#{selected_features}") do
      #Cache miss, so let's calculate it
      weighted_averages = {}
      catlabel = {}
      all_product_ids = []
      clusters.each do |c|
        weighted_averages[c.id] = {}
        catlabel[c.id] = []
        product_ids = c.nodes.map {|n| n.product_id }
        all_product_ids += product_ids
        rules = BoostexterRule.bycluster(c.id)
        rules.each do |r|
          # This check will not work in future, but will work for now. There will be a type field in the YAML representation instead.
          brules = YAML.load(r.yaml_repr)
          #Threshold rule
          next if brules.empty?
          z = 0
          weighted_average = 0
          ContSpec.cachemany(product_ids,r.fieldname).each do |feature_value|
            next unless feature_value
            weight = BoostexterRule.find_weight_for_value(brules, feature_value)
            weighted_average += weight * feature_value
            z += weight
          end
          next if z == 0 # Loop back to the beginning; do not add this field name for this cluster.
          weighted_averages[c.id][r.fieldname] = weighted_average / z
        end
      end
      results = []
      weighted_averages.each do |cluster_id,featurehash|
        current_cluster_tagline = []
        featurehash.each do |featurename,weighted_average|
          quartiles = BoostexterRule.compute_quartile(featurename,all_product_ids)
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
        res = current_cluster_tagline+catlabel[cluster_id]
        results << (res.empty? ? ["average"] : res)
      end
      results
      # [ ["avgdisplaysize", "highminimumfocallength"],["avgprice", ""] , ...] 
    end 
  end
  
  def self.compute_quartile(feat,product_ids)
    q25offset = (Session.current.search.result_count / 4.0).floor
    q75offset = ((Session.current.search.result_count * 3) / 4.0).floor
    q25 = ContSpec.find(:first, :select => 'value', :offset => q25offset, :order => 'value', :conditions => ["product_id IN (?) and name = ?", product_ids, feat]).value
    q75 = ContSpec.find(:first, :select => 'value', :offset => q75offset, :order => 'value', :conditions => ["product_id IN (?) and name = ?", product_ids, feat]).value
    [q25,q75]
  end
  
  def self.find_weight_for_value(unpacked_weighted_intervals, feature_value)
    weight = 0
    unpacked_weighted_intervals.each do |uwi| 
      #uwi[0] = interval [min,max]
      #uwi[1] = weight
      if (uwi[0][0] < feature_value && uwi[0][1] >= feature_value)
        weight = uwi[1]
        break
      end
    end
    weight
  end
end
