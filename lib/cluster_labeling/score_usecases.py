#!/usr/bin/env python
import os
import sys

try:
    version = int(sys.argv[1])
    root_path = sys.argv[2]
    config_name = sys.argv[3]
    product_type = sys.argv[4]
except (IndexError, ValueError):
    print "score_usecases.py [version] [root_path] [config_name] [product_type]"
    sys.exit(-1)

database_yaml_fn = os.path.join(root_path, "config/database.yml")

os.chdir(root_path)
sys.path.append(os.path.join(root_path, "lib/"))

import cluster_labeling.django_settings as django_settings
django_settings.configure_django(database_yaml=database_yaml_fn,
                                 config_name=config_name)

import cluster_labeling.optemo_django_models as optemo
optemo.set_optemo_product_type(product_type)

import cluster_labeling.usecases as usecases

if not usecases.UsecaseClusterScore.all_tables_exist()[0]:
    usecases.UsecaseClusterScore.drop_tables_if_exist()
    usecases.UsecaseClusterScore.create_tables()

usecases.score_usecases_for_all_clusters(version)
