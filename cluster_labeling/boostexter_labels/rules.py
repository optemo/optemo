class BoosTexterRule(object):
    fieldname = None
    weights = None

    def __init__(self, fieldname, weights):
        self.fieldname = fieldname
        self.weights = weights

class BoosTexterThresholdRule(BoosTexterRule):
    threshold = None

    def __init__(self, fieldname, weights, threshold):
        BoosTexterRule.__init__(self, fieldname, weights)
        self.threshold = threshold

class BoosTexterSGramRule(BoosTexterRule):
    sgram = None

    def __init__(self, fieldname, weights, sgram):
        BoosTexterRule.__init__(self, fieldname, weights)
        self.sgram = sgram

def gather_rules(rules):
    rules_a = {}

    for rule in rules:
        fieldname = rule.fieldname
        rules_for_fieldname = rules_a.get(fieldname, [])
        rules_for_fieldname.append(rule)
        rules_a[fieldname] = rules_for_fieldname

    return rules_a

def get_abs_weight_from_threshold_rule(rule):
    weights = rule.weights
    weights = weights[2, :] - weights[1, :]

    assert(abs(weights[0]) == abs(weights[1]))

    return abs(weights[0])

def get_interval_from_threshold_rule(rule):
    weights = rule.weights
    weights = weights[2, :] - weights[1, :]

    if weights[0] > 0 and weights[1] < 0:
        return [[rule.threshold, Inf], float(abs(weights[0]))]
    elif weights[0] < 0 and weights[1] > 0:
        return [[-Inf, rule.threshold], float(abs(weights[0]))]
    else:
        assert(False)

def get_rule_type(rule):
    return str(type(rule))

def all_rules_are_for_same_field(rules):
    rule_types = set(map(lambda x: get_rule_type(x), rules))
    return len(rule_types) == 1
