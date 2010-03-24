#!/usr/bin/env python
import os
import sys

try:
    version = int(sys.argv[1])
    root_path = sys.argv[2]
    config_name = sys.argv[3]
except (IndexError, ValueError):
    print "save_combined_boostexter_rules.py [version] [root_path] [config_name]"
    sys.exit(-1)

database_yaml_fn = os.path.join(root_path, "config/database.yml")
    
os.chdir(root_path)
sys.path.append(os.path.join(root_path, "lib/"))

import cluster_labeling.django_settings as django_settings
django_settings.configure_django(database_yaml=database_yaml_fn,
                                 config_name=config_name)

import cluster_labeling.boostexter_labels as b_lbls
b_lbls.save_combined_rules_for_all_clusters(version)
