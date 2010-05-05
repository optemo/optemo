class BoostexterRule < ActiveRecord::Base
  # This is a good idea, but right now the boostexter_combined_rules only works for cameras (March 23). Update this in future.
  def self.bycluster(cluster_id)
    CachingMemcached.cache_lookup("BoostexterRules#{cluster_id}") do
      PrinterBoostexterCombinedRule.find(:all, :order => "weight DESC", :conditions => {"cluster_id" => cluster_id})
    end
  end
  
  def self.clusterLabels(clusters)
    return if clusters.empty?
    ActiveRecord::Base.include_root_in_json = false # json conversion is used below, and this makes it cleaner
    cluster_ids = clusters.map(&:id).join("-")
    selected_features = (Session.current.search.userdataconts.map{|c| c.name+c.min.to_s+c.max.to_s}+Session.current.search.userdatabins.map{|c| c.name+c.value.to_s}+Session.current.search.userdatacats.map{|c| c.name+c.value}).hash
    CachingMemcached.cache_lookup("#{$product_type}Taglines#{cluster_ids}#{selected_features}") do
      #Cache miss, so let's calculate it
      weighted_averages = {}
      catlabel = {}
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
                weight = BoostexterRule.find_weight_for_value(unpacked_weighted_intervals, feature_value)
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
      results = []
      weighted_averages.each do |cluster_id,featurehash|
        current_cluster_tagline = []
        featurehash.each do |featurename,weighted_average|
          quartiles = BoostexterRule.compute_quartile(featurename)
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
  
  def self.compute_quartile(featurename)
    # This can be sped up by the following: Instead of fetching p.maximumresolution, then p.displaysize, etc.,
    # just do a single query for p. If there are multiple features to fetch, the rest of the query is guaranteed to be identical
    # and doing activerecord caching will help
    filter_query_thing = ""
    filter_query_thing = Cluster.filterquery('n.') + " AND " unless Cluster.filterquery('n.').blank?
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
  
  def self.find_weight_for_value(unpacked_weighted_intervals, feature_value)
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
