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
  
  def gather_rules(rules)
    rules_a = {}
    
    for rule in rules
      fieldname = rule.fieldname
      rules_for_fieldname = nil

      if rules_a.has_key?(fieldname)
        rules_for_fieldname = rules_a[fieldname]
      else
        rules_for_fieldname = []
      end
      
      rules_for_fieldname.append(rule)
      rules_a[fieldname] = rules_for_fieldname
    end

    return rules_a
  end

  def get_abs_weight_from_threshold_rule(rule)
    weights = [0, 0]
    weights[0] = rule.weights[2][0] - rule.weights[1][0]
    return abs(weights[0])
  end

  def get_interval_from_threshold_rule(rule):
    weights = [0, 0]
    weights[0] = rule.weights[2][0] - rule.weights[1][0]
    weights[1] = rule.weights[2][1] - rule.weights[1][1]
    
    if weights[0] == 0 and weights[1] == 0:
        return None
    elsif weights[0] > 0 and weights[1] < 0:
        return [[rule.threshold, Infinity], float(abs(weights[0]))]
    elsif weights[0] < 0 and weights[1] > 0:
        return [[-Infinity, rule.threshold], float(abs(weights[0]))]
    end
  end

  def all_rules_are_same_type(rules)
    rule_types = Set.new(rules.map{|r| r.class}).size()
  end
end
