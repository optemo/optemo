#!/usr/bin/env python
import os
import sys

os.environ.setdefault('SCRAPY_SETTINGS_MODULE', 'synscrape.settings')

try:
    if len(sys.argv) < 5:
        raise ValueError
    
    root_path = sys.argv[1]
    config_name = sys.argv[2]
    product_type = sys.argv[3]
except (IndexError, ValueError):
    print "scrapy-ctl.py [root_path] [config_name] [product_type] <other-scrapy-ctl-opts>"
    sys.exit(-1)

database_yaml_fn = os.path.join(root_path, "config/database.yml")
    
os.chdir(root_path)
sys.path.append(os.path.join(root_path, "lib/"))

import cluster_labeling.django_settings as django_settings
django_settings.configure_django(database_yaml=database_yaml_fn,
                                 config_name=config_name)

import cluster_labeling.optemo_django_models as optemo
optemo.set_optemo_product_type(product_type)

sys.argv = sys.argv[3:]

from scrapy.command.cmdline import execute
execute()
