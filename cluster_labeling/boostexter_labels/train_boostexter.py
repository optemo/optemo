#!/usr/bin/env python
import os
import sys

root_path = '/optemo/site'

os.chdir(root_path)
execfile('cluster_labeling/django_setting.py')
os.chdir(root_path)

sys.path.append(root_path)


import cluster_labeling.boostexter_labels as b_lbls

# Only runs on Linux (not on OS X) because boostexter executable is
# more than 10 years old.
b_lbls.train_boostexter_on_all_clusters(version)

