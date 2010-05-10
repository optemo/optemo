require 'rules'
require 'weighted_intervals'
require 'rule_parsing'

module BtxtrLabels
  def BtxtrLabels.get_max_abs_weight_from_threshold_rules(rules)
    return rules.map{|r| get_abs_weight_from_threshold_rule(r)}.max()
  end
  
  def BtxtrLabels.get_weighted_interval_set_from_threshold_rules(rules)
    # Find the intervals encoded in the rules. These intervals may not
    # be contiguous, i.e. everything with really wide or really narrow
    # zoom ranges.
    intervals = rules.map{|r| get_interval_from_threshold_rule(r)}.find_all{|i| i != nil}

    interval_set = []

    for interval in intervals
      interval_set = merge_interval_with_interval_set(interval, interval_set)
    end

    return interval_set
  end
  
  def BtxtrLabels.combine_threshold_rules(cluster, fieldname, rules)
    max_abs_weight = get_max_abs_weight_from_threshold_rules(rules)
    interval_set = get_weighted_interval_set_from_threshold_rules(rules)

    if is_interval_set_disjoint(interval_set)
      return nil, nil
    end

    avg_w = compute_weighted_average(cluster, fieldname, interval_set)

    # All of the cluster's products had NULL values for this field, so
    # nothing can be said about whether it is low, average or
    # high. There will be no label for the field.
    if avg_w == nil
        return nil, nil
    end

    q_25, q_75 = compute_parent_cluster_quartiles(cluster, fieldname)

    ranking_idx = nil

    if avg_w <= q_25
      ranking_idx = 0
    elsif q_25 < avg_w and avg_w < q_75
      ranking_idx = 1
    elsif q_75 <= avg_w
      ranking_idx = 2
    else
      raise "Invalid ranking"
    end

    # Construct and return a string that will then get translated
    # using the lookup tables located in config/locales/models/en.yml.
    ranking = ['lower', 'avg', 'higher']
    return max_abs_weight, ranking[ranking_idx] + fieldname
  end

  def BtxtrLabels.is_stopword(word)
    return false # This should be implemented.
  end
  
  def BtxtrLabels.find_best_sgram_from_rules(fieldname, rules)
    # Just pick the meaningful sgram with highest weight and check
    # whether it is a positive label or a negative label.
    max_abs_weight = 0
    max_abs_weight_sgram = nil

    for rule in rules
      if is_stopword(rule.sgram)
        next
      end

      sgram = rule.sgram
      direction = nil

      weights = [0, 0]
      weights[0] = rule.weights[1][0] - rule.weights[0][0]
      weights[1] = rule.weights[1][1] - rule.weights[0][1]

      if weights[0].abs != weights[1].abs
        raise "These two values should be the same"
      end

      weight = weights[0]

      if weight.abs <= max_abs_weight
        next
      end

      direction = nil
      if weight > 0
        direction = 1
      elsif
        direction = -1
      else
        raise "Rule weight should not be zero"
      end

      max_abs_weight = weight.abs
      max_abs_weight_sgram = {'sgram' => sgram, 'direction' => direction}
    end

    if max_abs_weight == 0
      return nil, nil
    else
      return max_abs_weight, max_abs_weight_sgram
    end
  end
  
  def BtxtrLabels.combine_boolean_rules(fieldname, rules)
    # So.. boolean rules are not selected at all, because pretty much
    # all of the boolean flags are NULL.
    return nil
  end
  
  def BtxtrLabels.convert_interval_set_to_yaml_style(interval_set)
    return interval_set.map{|x| {'interval' => x[0], 'weight' => x[1]}}
  end
  
  def BtxtrLabels.save_combined_threshold_rule_for_field(cluster, fieldname, rules)
    max_abs_weight = get_max_abs_weight_from_threshold_rules(rules)
    interval_set = get_weighted_interval_set_from_threshold_rules(rules)

    if is_interval_set_disjoint(interval_set)
      return nil, nil
    end

    yaml_repr = YAML::dump(convert_interval_set_to_yaml_style(interval_set))
    
    atts = {:fieldname => fieldname, :weight => max_abs_weight,
    :cluster_id => cluster.id, :version => cluster.version,
    :rule_type => "T", :yaml_repr => yaml_repr}
    combined_rule = BoostexterRule.find_by_cluster_id_and_version_and_fieldname(cluster.id,cluster.version,fieldname)
    if combined_rule.nil?
      combined_rule = BoostexterRule.new(atts).save 
    else
      combined_rule.update_attributes(atts)
    end
  end
  
  def BtxtrLabels.save_combined_sgram_rule_for_field(cluster, fieldname, rules)
    max_abs_weight, sgram = find_best_sgram_from_rules(fieldname, rules)

    if max_abs_weight == nil
      if sgram != nil
        raise "Error"
      end

      return nil, nil
    end

    yaml_repr = YAML::dump(sgram)
    
    atts = {:fieldname => fieldname, :weight => max_abs_weight,
    :cluster_id => cluster.id, :version => cluster.version,
    :rule_type => "S", :yaml_repr => yaml_repr}
    combined_rule = BoostexterRule.find_by_cluster_id_and_version_and_fieldname(cluster.id,cluster.version,fieldname)
    if combined_rule.nil?
      combined_rule = BoostexterRule.new(atts).save 
    else
      combined_rule.update_attributes(atts)
    end
  end
  
  def BtxtrLabels.save_combined_rule_for_field(cluster, fieldname, rules)
    if not all_rules_are_same_type(rules)
      raise "All rules should be same type"
    end

    rule_type = rules[0].class

    if rule_type == BtxtrThresholdRule
      save_combined_threshold_rule_for_field(cluster, fieldname, rules)
    elsif rule_type == BtxtrSGramRule
      save_combined_sgram_rule_for_field(cluster, fieldname, rules)
    else
      raise "Unknown rule type"
    end
  end
    
  def BtxtrLabels.save_combined_rules_for_cluster(cluster)
    get_rules(cluster).group_by(&:fieldname).each_pair do |fieldname, rules_for_field|
      save_combined_rule_for_field(cluster, fieldname, rules_for_field)
    end
  end
end
