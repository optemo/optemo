import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.local_django_models as local
from django.db import models

from cluster_labeling.boostexter_labels.rules import *
from . import rule_parsing as rp

from cluster_labeling.boostexter_labels.weighted_intervals import *

RULE_TYPES = (('T', 'Threshold'),
              ('S', 'Sgram'))

class BoosTexterCombinedRule(local.LocalModel):
    class Meta:
        db_table = "%s_%s" % (optemo.product_type_tablename_prefix,
                              "boostexter_combined_rules")
        unique_together = (("fieldname", "cluster_id", "version"))
    
    fieldname = models.CharField(max_length=255)

    # Used to rank combined rules against each other
    weight = models.FloatField()

    cluster_id = models.IntegerField()
    version = models.IntegerField()

    rule_type = models.CharField(max_length=1, choices=RULE_TYPES)
    yaml_repr = models.TextField()

def get_max_abs_weight_from_threshold_rules(rules):
    return max(map(lambda r: get_abs_weight_from_threshold_rule(r),
                   rules))

def get_weighted_interval_set_from_threshold_rules(rules):
    # Find the intervals encoded in the rules. These intervals may not
    # be contiguous, i.e. everything with really wide or really narrow
    # zoom ranges.
    intervals = filter(lambda x: x is not None,
                       map(get_interval_from_threshold_rule, rules))
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

    ranking_idx = None

    if avg_w <= q_25:
        ranking_idx = 0
    elif q_25 < avg_w and avg_w < q_75:
        ranking_idx = 1
    elif q_75 <= avg_w:
        ranking_idx = 2
    else:
        assert(False)

    # Construct and return a string that will then get translated
    # using the lookup tables located in config/locales/models/en.yml.
    ranking = ['lower', 'avg', 'higher']
    return max_abs_weight, ranking[ranking_idx] + fieldname

import cluster_labeling.text_handling as th

def find_best_sgram_from_rules(fieldname, rules):
    # Just pick the meaningful sgram with highest weight and check
    # whether it is a positive label or a negative label.
    max_abs_weight = 0
    max_abs_weight_sgram = None

    for rule in rules:
        if th.is_stopword(rule.sgram):
            continue
            
        sgram = rule.sgram
        direction = None

        weights = rule.weights
        weights = weights[1, :] - weights[0, :]

        assert(abs(weights[0]) == abs(weights[1]))
        weight = weights[0]

        if abs(weight) <= max_abs_weight:
            continue

        direction = None
        if weight > 0:
            direction = 1
        elif weight < 0:
            direction = -1
        else:
            assert(False)

        max_abs_weight = abs(weight)
        max_abs_weight_sgram = {'sgram':sgram, 'direction':direction}

    if max_abs_weight == 0:
        return None, None
    else:
        return max_abs_weight, max_abs_weight_sgram

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
         version=cluster.version, rule_type='T', yaml_repr=yaml_repr)

    combined_rule.save()

def save_combined_sgram_rule_for_field(cluster, fieldname, rules):
    max_abs_weight, sgram = find_best_sgram_from_rules(fieldname, rules)

    if max_abs_weight is None:
        assert(sgram is None)
        return None, None

    yaml_repr = yaml.dump(sgram)
    
    combined_rule = \
        BoosTexterCombinedRule\
        (fieldname=fieldname,
         weight=max_abs_weight, cluster_id=cluster.id,
         version=cluster.version, rule_type='S', yaml_repr=yaml_repr)

    combined_rule.save()

def save_combined_rule_for_field(cluster, fieldname, rules):
    assert(all_rules_are_for_same_field(rules))

    rule_type = get_rule_type(rules[0])

    if rule_type == str(BoosTexterThresholdRule):
        save_combined_threshold_rule_for_field\
        (cluster, fieldname, rules)
    elif rule_type == str(BoosTexterSGramRule):
        save_combined_sgram_rule_for_field(cluster, fieldname, rules)
    else:
        assert(False)

def save_combined_rules_from_rules(cluster, rules):
    # Put all rules for a particular field together
    rules_a = gather_rules(rules)

    for (fieldname, rules_for_field) in rules_a.iteritems():
        save_combined_rule_for_field\
            (cluster, fieldname, rules_for_field)

def save_combined_rules_for_cluster(cluster):
    rules = rp.get_rules(cluster)
    save_combined_rules_from_rules(cluster, rules)
