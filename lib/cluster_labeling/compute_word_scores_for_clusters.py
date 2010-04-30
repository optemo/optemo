#!/usr/bin/env python
import os
import sys

try:
    version = int(sys.argv[1])
    root_path = sys.argv[2]
    config_name = sys.argv[3]
    product_type = sys.argv[4]
    score_type = sys.argv[5]
except (IndexError, ValueError):
    print "compute_word_scores_for_clusters.py [version] [root_path] [config_name] [product_type] [score_type]"
    sys.exit(-1)

database_yaml_fn = os.path.join(root_path, "config/database.yml")

os.chdir(root_path)
sys.path.append(os.path.join(root_path, "lib/"))

import cluster_labeling.django_settings as django_settings
django_settings.configure_django(database_yaml=database_yaml_fn,
                                 config_name=config_name)

import cluster_labeling.optemo_django_models as optemo
optemo.set_optemo_product_type(product_type)

if score_type == 'chi_squared':
    import nh_chi_scorer as chi
    chi.compute_all_chi_squared_scores(version)
elif score_type == 'mi':
    import nh_mi_scorer as mi
    mi.compute_all_MI_scores(version)
else:
    assert(False)
