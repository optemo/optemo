#!/usr/bin/env python
import os
import sys

root_path = '/optemo/site'

os.chdir(root_path)
execfile('cluster_labeling/django_setting.py')
os.chdir(root_path)

from cluster_labeling.boostexter_labels import *

version = int(sys.argv[1])

# Only runs on Linux (not on OS X) because boostexter executable is
# more than 10 years old.
train_boostexter_on_all_clusters(version)
