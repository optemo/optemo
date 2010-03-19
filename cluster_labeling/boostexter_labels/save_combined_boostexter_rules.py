#!/usr/bin/env python
import os
import sys

try:
    version = int(sys.argv[1])
    root_path = sys.argv[2]
except (IndexError, ValueError):
    print "save_combined_boostexter_rules.py [version] [root_path]"
    print "eg. save_combined_boostexter_rules.py 70 /optemo/site"
    print "eg. save_combined_boostexter_rules.py 23 /u/apps/laserprinterhub/current"
    sys.exit(-1)
    
os.chdir(root_path)
execfile('cluster_labeling/django_settings.py')
os.chdir(root_path)

sys.path.append(root_path)

import cluster_labeling.boostexter_labels as b_lbls



b_lbls.save_combined_rules_for_all_clusters(version)

