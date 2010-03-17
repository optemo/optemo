import cluster_labeling.boostexter_labels.filenames as fn

import re

class ParseError(Exception):
    line = None
    
    def __init__(self, line):
        self.line = line

    def __str__(self):
        return repr(self.line)

def is_blankline(line):
    return re.match('^\s*$', line) != None

rule_header_re = \
re.compile('^\s*(\d+(\.\d+)?)\s+Text:([A-Z]+):([a-z_]+):([A-Za-z0-9_#\(\)\n\.]+)?\s*$')
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
        rule_info['sgram'] = re.sub('[#\s]', ' ', match.group(5)).strip()

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
    filename = fn.get_strong_hypothesis_filename(cluster)
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
