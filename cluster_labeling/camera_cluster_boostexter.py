#!/usr/bin/env python
import cluster_labeling.optemo_django_models as optemo
import subprocess
import time

import re

output_subdir = 'cluster_labeling/cc_boostexter_files/'
boostexter_subdir = 'cluster_labeling/BoosTexter2_1/'

boosting_fields = [
    ('title', 'text'),
    ('brand', 'text'),
    ('model', 'text'),
    
    ('itemwidth', 'continuous'),
    ('itemlength', 'continuous'),
    ('itemheight', 'continuous'),
    ('itemweight', 'continuous'),

    ('opticalzoom', 'continuous'),
    ('digitalzoom', 'continuous'),

    ('slr', ['True', 'False']),
    ('waterproof', ['True', 'False']),

    ('maximumfocallength', 'continuous'),
    ('minimumfocallength', 'continuous'),

    ('batteriesincluded', ['True', 'False']),

    ('connectivity', 'text'),
    
    ('hasredeyereduction', ['True', 'False']),
    ('includedsoftware', 'text'),

    ('averagereviewrating', 'continuous'),
    ('totalreviews', 'continuous'),

    ('price', 'continuous'),
    ('price_ca', 'continuous')
    ]

def get_labels(cluster):
    return [cluster.id, cluster.parent_id]

def get_names_filename(cluster):
    filestem = output_subdir + str(cluster.id)
    filename = filestem + ".names"
    return filename

def generate_names_file(cluster):
    filename = get_names_filename(cluster)
    f = open(filename, 'w')

    labels = get_labels(cluster)
    f.write(', '.join(map(str, labels)) + '.\n')

    for fieldname, fielddesc in boosting_fields:
        f.write(fieldname + ": ")

        if type(fielddesc) == list:
            f.write(', '.join(map(str, fielddesc)) + '.')
        elif type(fielddesc) == str:
            f.write(fielddesc + '.')
        else:
            raise Exception("Invalid field desc type %s" %
                            (str(type(fielddesc))))

        f.write('\n')

    f.close()

def get_data_filename(cluster):
    filestem = output_subdir + str(cluster.id)
    filename = filestem + ".data"
    return filename

def generate_data_file(cluster):
    filename = get_data_filename(cluster)
    f = open(filename, 'w')

    version = cluster.version

    cameras_this = map(lambda x: (x.get_product(), cluster.id),
                       cluster.get_nodes())

    parent_cluster_nodes = None
    if cluster.parent_id == 0:
        clusters = optemo.CameraCluster.get_manager()\
                   .filter(parent_id = 0, version=version)

        parent_cluster_nodes = []
        for parent_child_cluster in clusters:
            parent_cluster_nodes.extend(parent_child_cluster.get_nodes())
    else:
        parent_cluster = optemo.CameraCluster.get_manager()\
                         .filter(id = cluster.parent_id)[0]
        parent_cluster_nodes = parent_cluster.get_nodes()

    cameras_parent = \
        filter(lambda x:
               cluster.id not in
                   set(map(lambda y: y.id, x.get_clusters(cluster.version))),
               map(lambda x: x.get_product(), parent_cluster_nodes))
    
    cameras_parent = map(lambda x: (x, cluster.parent_id), cameras_parent)

    cameras = cameras_this
    cameras.extend(cameras_parent)
    
    for camera, cluster_id in cameras:
        for fieldname, fielddesc in boosting_fields:
            fieldval = camera.__getattribute__(fieldname)

            if fielddesc == ['True', 'False']:
                if fieldval == '1' or fieldval == 'True':
                    fieldval = 'True'
                else:
                    fieldval = 'False'
            elif fieldval == None:
                fieldval = '?' # unknown value

            fieldval = re.sub(u'([-:,&]|#)', ' ', unicode(fieldval), re.UNICODE)
            fieldval = re.sub(u'(\w+)\.(\D|$)', r'\1 \2', unicode(fieldval), re.UNICODE)

            f.write(fieldval.encode('utf-8') + ', ')

        f.write(str(cluster_id) + '.\n')

def train_boostexter(cluster):
    # See the boosexter README for description of commands
    boostexter_prog = boostexter_subdir + 'boostexter'
    boostexter_args = [
        '-n', str(20), # numrounds 
        '-W', str(2), # ngram_maxlen
        '-N', 'ngram', # ngram_type
        '-S', output_subdir + str(cluster.id) # 'filename_stem'
        ]

    cmd = [boostexter_prog]
    cmd.extend(boostexter_args)

    proc = subprocess.Popen(cmd)
    retcode = proc.wait()
    assert(retcode == 0)

def get_strong_hypothesis_filename(cluster):
    filestem = output_subdir + str(cluster.id)
    filename = filestem + ".shyp"
    return filename    

from numpy import *

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

class ParseError(Exception):
    line = None
    
    def __init__(self, line):
        self.line = line

    def __str__(self):
        return repr(self.line)

def is_blankline(line):
    return re.match('^\s*$', line) != None

rule_header_re = \
re.compile('^\s*(\d+(\.\d+)?)\s+Text:([A-Z]+):([a-z_]+):([A-Za-z_]+)?\s*$')
def parse_rule_header(line):
    match = rule_header_re.match(line)

    if match == None:
        raise ParseError(line)

    # Not sure what this number is for. Rule weight?
    _ = match.group(1)

    rule_info = {}

    rule_info['type'] = match.group(3)
    rule_info['fieldname'] = match.group(4)

    if rule_info['type'] == 'SGRAM':
        rule_info['sgram'] = match.group(5)

    return rule_info

number_line_re = \
re.compile('^\s*(-?\d+(\.\d+)?)\s+(-?\d+(\.\d+)?)\s*$')
def parse_number_line(line):
    match = number_line_re.match(line)

    if match == None:
        raise ParseError(line)

    return float(match.group(1)), float(match.group(3))

def parse_sgram_rule(fieldname, sgram, fh):
    weights = zeros((2, 2))
    rowidx = 0

    while(True):
        line = fh.readline()
        if line == '':
            raise ParseError(line)
        elif is_blankline(line):
            continue
        
        weights[rowidx, :] = parse_number_line(line)
        rowidx += 1

        if rowidx == 2:
            break

    return BoosTexterSGramRule(fieldname, weights, sgram)

def parse_threshold_rule(fieldname, fh):
    weights = zeros((3, 2))
    threshold = None
    
    rowidx = 0

    while(True):
        line = fh.readline()
        if line == '':
            raise ParseError(line)
        elif is_blankline(line):
            continue

        weights[rowidx, :] = parse_number_line(line)
        rowidx += 1

        if rowidx == 3:
            break

    while(True):
        line = fh.readline()
        if line == '':
            raise ParseError(line)
        elif is_blankline(line):
            continue

        match = re.match('^\s*(-?\d+(\.\d+)?)\s*$', line)
        if match == None:
            raise ParseError(line)
        threshold = float(match.group(1))

        break

    return BoosTexterThresholdRule(fieldname, weights, threshold)

def parse_next_rule(fh):
    # Find the rule header
    line = None
    
    while(True):
        line = fh.readline()
        if line == '':
            return None
        elif is_blankline(line):
            continue
        else:
            break

    rule_info = parse_rule_header(line)

    # Parse the rule!
    if rule_info['type'] == 'THRESHOLD':
        rule = parse_threshold_rule(rule_info['fieldname'], fh)
        return rule
    elif rule_info['type'] == 'SGRAM':
        rule = parse_sgram_rule(rule_info['fieldname'],
                                rule_info['sgram'], fh)
        return rule
    else:
        raise ParseError(line)

def get_rules(cluster):
    filename = get_strong_hypothesis_filename(cluster)
    shyp = open(filename, 'r')

    numrules = int(re.match('(\d+)', shyp.readline()).group(1))

    rules = []
    while(True):
        rule = parse_next_rule(shyp)

        if rule == None:
            break

        rules.append(rule)

    assert(len(rules) == numrules)
    return rules

def gather_rules(rules):
    rules_a = {}

    for rule in rules:
        fieldname = rule.fieldname
        rules_for_fieldname = rules_a.get(fieldname, [])
        rules_for_fieldname.append(rule)
        rules_a[fieldname] = rules_for_fieldname

    return rules_a

import operator

def get_field_ranks(rules):
    field_ranks = {}

    i = 0
    for rule in rules:
        fieldname = rule.fieldname
        if fieldname in field_ranks:
            continue
        
        field_ranks[fieldname] = i
        i += 1

    return map(lambda f, r: f,
               sorted(field_ranks.iteritems(),
                      key=operator.itemgetter(1)))

import cluster_labeling.nh_labeler as nh

def combine_sgram_rules(fieldname, rules):
    # Just pick the first meaningful sgram and check whether it is a
    # positive label or a negative label.
    for rule in rules:
        if nh.is_stopword(rule.sgram):
            continue
            
        label = rule.sgram
        direction = None

        weights = rule.weights
        weights = weights[1, :] - weights[0, :]

        if weights[0] > 0 and weights[1] < 0:
            direction = 'pos'
        elif weights[0] < 0 and weights[1] > 0:
            direction = 'neg'
        else:
            assert(False)

        print label, direction

        # return label, direction

def make_label_for_rules_for_field(fieldname, rules):
    rule_types = set(map(lambda x: str(type(x)), rules))
    assert(len(rule_types) == 1)

    rule_type = rule_types.pop()

    if rule_type == str(BoosTexterThresholdRule):
        return combine_threshold_rules(fieldname, rules)
    elif rule_type == str(BoosTexterSGramRule):
        return combine_sgram_rules(fieldname, rules)
    else:
        assert(False)

def make_labels_from_rules(rules):
    # Put all rules for a particular field together
    rules_a = gather_rules(rules)
    field_ranks = get_field_ranks(rules)

    labels = []
    for fieldname in field_ranks:
        label = make_label_for_rules_for_field\
                (fieldname, rules_a[fieldname])
        labels.append(label)

def make_boostexter_labels_for_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)

    cluster_labels = []

    for cluster in qs:
        rules = get_rules(cluster)
        labels = make_labels_from_rules(rules)
        cluster_labels.append((cluster.id, labels))

    return cluster_labels

def train_boostexter_on_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        generate_names_file(cluster)
        generate_data_file(cluster)
        train_boostexter(cluster)
