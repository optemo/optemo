#!/usr/bin/env python
import os
import sys

root_path = '/optemo/site'

os.chdir(root_path)
execfile('cluster_labeling/django_settings.py')
os.chdir(root_path)

from cluster_labeling.boostexter_labels import *

version = int(sys.argv[1])

save_combined_rules_for_all_clusters(version)
