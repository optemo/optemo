import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.local_django_models as local
from django.db import models

class BoosTexterCombinedRule(local.LocalModel):
    class Meta:
        db_table = "boostexter_combined_rules"
        unique_together = (("fieldname", "cluster_id", "version"))
    
    fieldname = models.CharField(max_length=255)

    # Used to rank combined rules against each other
    weight = models.FloatField()

    cluster_id = models.IntegerField()
    version = models.IntegerField()
    
    yaml_repr = models.TextField()

def get_max_abs_weight_from_threshold_rules(rules):
    return max(map(lambda r: get_abs_weight_from_threshold_rule(r),
                   rules))

def get_weighted_interval_set_from_threshold_rules(rules):
    # Find the intervals encoded in the rules. These intervals may not
    # be contiguous, i.e. everything with really wide or really narrow
    # zoom ranges.
    intervals = map(get_interval_from_threshold_rule, rules)
    interval_set = []

    for interval in intervals:
        interval_set = \
            merge_interval_with_interval_set(interval, interval_set)

    return interval_set

def combine_threshold_rules(cluster, fieldname, rules):
    max_abs_weight = get_max_abs_weight_from_threshold_rules(rules)
    interval_set = get_weighted_interval_set_from_threshold_rules(rules)

    if is_interval_set_disjoint(interval_set):
        return None, None

    avg_w = compute_weighted_average(cluster, fieldname, interval_set)

    # All of the cluster's products had NULL values for this field, so
    # nothing can be said about whether it is low, average or
    # high. There will be no label for the field.
    if avg_w == None:
        return None, None

    q_25, q_75 = compute_parent_cluster_quartiles(cluster, fieldname)

    label_idx = None

    if avg_w <= q_25:
        label_idx = 0
    elif q_25 < avg_w and avg_w < q_75:
        label_idx = 1
    elif q_75 <= avg_w:
        label_idx = 2
    else:
        assert(False)

    if label_idx == 1:
        # The label_idx is the neutral one, i.e. 'Average'. Don't
        # bother making a label for neutral quantities.
        return None, None

    quality_desc = fieldname_to_quality[fieldname]
    full_labels_given = quality_desc[2]

    if full_labels_given:
        return max_abs_weight, quality_desc[1][label_idx]
    else:
        return max_abs_weight,\
               quality_desc[1][label_idx] + " " + quality_desc[0]

import cluster_labeling.text_handling as th

def combine_sgram_rules(fieldname, rules):
    # Just pick the meaningful sgram with highest weight and check
    # whether it is a positive label or a negative label.
    max_abs_weight = 0
    max_abs_weight_label = None

    for rule in rules:
        if th.is_stopword(rule.sgram):
            continue
            
        label = rule.sgram
        direction = None

        weights = rule.weights
        weights = weights[1, :] - weights[0, :]

        assert(abs(weights[0]) == abs(weights[1]))
        weight = weights[0]

        if abs(weight) <= max_abs_weight:
            continue

        if weight > 0:
            direction = 'pos'
        elif weight < 0:
            direction = 'neg'
        else:
            assert(False)

        quality_desc = fieldname_to_quality[fieldname]

        if direction == 'pos':
            label = quality_desc + ": " + label
        else:
            label = quality_desc + ": " + "Not " + label

        max_abs_weight = abs(weight)
        max_abs_weight_label = label

    if max_abs_weight == 0:
        return None, None
    else:
        return max_abs_weight, max_abs_weight_label

def combine_boolean_rules(fieldname, rules):
    # So.. boolean rules are not selected at all, because pretty much
    # all of the boolean flags are NULL.
    pass

import yaml

def convert_interval_set_to_yaml_style(interval_set):
    return map(lambda x: {'interval':x[0], 'weight':x[1]},
               interval_set)

def save_combined_threshold_rule_for_field(cluster, fieldname, rules):
    max_abs_weight = get_max_abs_weight_from_threshold_rules(rules)
    interval_set = get_weighted_interval_set_from_threshold_rules(rules)

    if is_interval_set_disjoint(interval_set):
        return None, None

    yaml_repr = \
        yaml.dump(convert_interval_set_to_yaml_style(interval_set))
    
    combined_rule = \
        BoosTexterCombinedRule\
        (fieldname=fieldname,
         weight=max_abs_weight, cluster_id=cluster.id,
         version=cluster.version, yaml_repr=yaml_repr)

    combined_rule.save()

def save_combined_sgram_rule_for_field(fieldname, rules):
    max_abs_weight, label = combine_sgram_rules(fieldname, rules)
    yaml_repr = yaml.dump({'label':label})
    
    combined_rule = \
        BoosTexterCombinedRule\
        (fieldname=fieldname,
         weight=max_abs_weight, cluster_id=cluster.id,
         version=cluster.version, yaml_repr=yaml_repr)

    combined_rule.save()

def save_combined_rule_for_field(cluster, fieldname, rules):
    assert(all_rules_are_for_same_field(rules))

    rule_type = get_rule_type(rules[0])

    if rule_type == str(BoosTexterThresholdRule):
        save_combined_threshold_rule_for_field\
        (cluster, fieldname, rules)
    elif rule_type == str(BoosTexterSGramRule):
        save_combined_sgram_rule_for_field(fieldname, rules)    
    else:
        assert(False)

def save_combined_rules_from_rules(cluster, rules):
    # Put all rules for a particular field together
    rules_a = gather_rules(rules)

    for (fieldname, rules_for_field) in rules_a.iteritems():
        save_combined_rule_for_field\
            (cluster, fieldname, rules_for_field)
        
