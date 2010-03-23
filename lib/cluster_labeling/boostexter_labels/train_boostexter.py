#!/usr/bin/env python
import os
import sys

os.chdir(root_path)
execfile('cluster_labeling/django_settings.py')
os.chdir(root_path)

sys.path.append(root_path)

import cluster_labeling.boostexter_labels as b_lbls

try:
    version = int(sys.argv[1])
    root_path = sys.argv[2]
except (IndexError, ValueError):
    print "train_boostexter.py [version] [root_path]"
    print "eg. train_boostexter 70 /optemo/site"
    print "or train_boostexter 24 /u/apps/laserprinterhub/current"
    sys.exit(-1)

# Only runs on Linux (not on OS X) because boostexter executable is
# more than 10 years old.
b_lbls.train_boostexter_on_all_clusters(version)

