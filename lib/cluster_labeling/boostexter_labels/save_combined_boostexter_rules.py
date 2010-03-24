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

import cluster_labeling.boostexter_labels.filepaths as fn
fn.output_subdir = \
    os.path.join(root_path, "lib/", fn.output_subdir)
fn.boostexter_subdir = \
    os.path.join(root_path, "lib/", fn.boostexter_subdir)

import cluster_labeling.boostexter_labels.combined_rules as cr
all_tables_exist, _, _ = cr.BoosTexterCombinedRule.all_tables_exist()
if not all_tables_exist:
    recreating_tables_msg = \
        "Tables missing for %s - dropping all %s tables and recreating" % \
        (str(cr.BoosTexterCombinedRule), str(cr.BoosTexterCombinedRule))
    print recreating_tables_msg
    cr.BoosTexterCombinedRule.drop_tables_if_exists()
    cr.BoosTexterCombinedRule.create_tables()

import cluster_labeling.boostexter_labels as b_lbls
b_lbls.save_combined_rules_for_all_clusters(version)
