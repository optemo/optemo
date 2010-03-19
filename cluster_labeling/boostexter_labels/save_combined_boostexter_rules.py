#!/usr/bin/env python
import os
import sys

root_path = '/optemo/site'

os.chdir(root_path)
execfile('cluster_labeling/django_settings.py')
os.chdir(root_path)

sys.path.append(root_path)

import cluster_labeling.boostexter_labels as b_lbls

try:
    version = int(sys.argv[1])
except (IndexError, ValueError):
    print "save_combined_boostexter_rules.py [version]"
    sys.exit(-1)

b_lbls.save_combined_rules_for_all_clusters(version)

