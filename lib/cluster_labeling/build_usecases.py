#!/usr/bin/env python
import os
import sys

try:
    version = int(sys.argv[1])
    root_path = sys.argv[2]
    config_name = sys.argv[3]
    product_type = sys.argv[4]
except (IndexError, ValueError):
    print "build_usecases.py [version] [root_path] [config_name] [product_type]"
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
import subprocess

usecases.populate_usecases()
usecases.populate_direct_indicators_for_usecases()

# import cluster_labeling.word_senses as ws
# if not ws.WordSense.all_tables_exist()[0]:
#     ws.WordSense.drop_tables_if_exist()
#     ws.WordSense.create_tables()

# cmd = "lib/cluster_labeling/synscrape/scrapy-ctl.py"
# cmd = [os.path.join(root_path, cmd)]
# cmd.extend(list(sys.argv[2:5]))
# cmd.extend(['crawl', 'thesaurus.com'])
# proc = subprocess.Popen(cmd)
# retcode = proc.wait()
# assert(retcode == 0)

usecases.populate_indicators_for_usecases()
