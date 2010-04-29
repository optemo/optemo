module BtxtrLabels
  Infinity = 1.0/0
  
  class BtxtrRule
    attr_accessor :fieldname, :weights

    def initialize(fieldname, weights)
      @fieldname = fieldname
      @weights = weights
    end
  end

  class BtxtrThresholdRule < BtxtrRule
    attr_accessor :threshold

    def initialize(fieldname, weights, threshold)
      super(fieldname, weights)
      @threshold = threshold
    end
  end

  class BtxtrSGramRule < BtxtrRule
    attr_accessor :sgram

    def initialize(fieldname, weights, sgram)
      super(fieldname, weights)
      @sgram = sgram
    end
  end
  
  def BtxtrLabels.gather_rules(rules)
    rules_a = {}
    
    for rule in rules
      fieldname = rule.fieldname
      rules_for_fieldname = nil

      if rules_a.has_key?(fieldname)
        rules_for_fieldname = rules_a[fieldname]
      else
        rules_for_fieldname = []
      end
      
      rules_for_fieldname.push(rule)
      rules_a[fieldname] = rules_for_fieldname
    end

    return rules_a
  end

  def BtxtrLabels.get_abs_weight_from_threshold_rule(rule)
    weights = [0, 0]
    weights[0] = rule.weights[2][0] - rule.weights[1][0]
    return weights[0].abs()
  end

  def BtxtrLabels.get_interval_from_threshold_rule(rule)
    weights = [0, 0]
    weights[0] = rule.weights[2][0] - rule.weights[1][0]
    weights[1] = rule.weights[2][1] - rule.weights[1][1]
    
    if weights[0] == 0 and weights[1] == 0
        return nil
    elsif weights[0] > 0 and weights[1] < 0
        return [[rule.threshold, Infinity], float(weights[0].abs())]
    elsif weights[0] < 0 and weights[1] > 0
        return [[-Infinity, rule.threshold], float(weights[0].abs())]
    end
  end

  def BtxtrLabels.all_rules_are_same_type(rules)
    rule_types = Set.new(rules.map{|r| r.class}).size()
  end
end
