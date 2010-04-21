#!/usr/bin/env python
import os
import sys

try:
    version = int(sys.argv[1])
    root_path = sys.argv[2]
    config_name = sys.argv[3]
    product_type = sys.argv[4]
except (IndexError, ValueError):
    print "train_boostexter.py [version] [root_path] [config_name] [product_type]"
    sys.exit(-1)

database_yaml_fn = os.path.join(root_path, "config/database.yml")

os.chdir(root_path)
sys.path.append(os.path.join(root_path, "lib/"))

import cluster_labeling.django_settings as django_settings
django_settings.configure_django(database_yaml=database_yaml_fn,
                                 config_name=config_name)

import cluster_labeling.optemo_django_models as optemo
optemo.set_optemo_product_type(product_type)

import cluster_labeling.boostexter_labels.filepaths as fn
fn.output_subdir = \
    os.path.join(root_path, "lib/", fn.output_subdir)
fn.boostexter_subdir = \
    os.path.join(root_path, "lib/", fn.boostexter_subdir)

# Check that the necessary paths exist
if not os.path.exists(fn.output_subdir):
    print "%s directory does not exist", (fn.output_subdir)

boostexter_progfn = 'boostexter'
if not os.path.exists(os.path.join(fn.boostexter_subdir, boostexter_progfn)):
    print "The boostexter executable %s does not exist", (fn.output_subdir)

# Only runs on Linux (not on OS X) because boostexter executable is
# more than 10 years old.
import cluster_labeling.boostexter_labels as b_lbls
b_lbls.train_boostexter_on_all_clusters(version)
