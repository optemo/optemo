#!/usr/bin/env python
import os
import sys

os.environ.setdefault('SCRAPY_SETTINGS_MODULE', 'synscrape.settings')

try:
    if len(sys.argv) < 4:
        raise ValueError
    
    root_path = sys.argv[1]
    config_name = sys.argv[2]
except (IndexError, ValueError):
    print "scrapy-ctl.py [root_path] [config_name] <other-scrapy-ctl-opts>"
    sys.exit(-1)

database_yaml_fn = os.path.join(root_path, "config/database.yml")
    
os.chdir(root_path)
sys.path.append(os.path.join(root_path, "lib/"))

import cluster_labeling.django_settings as django_settings
django_settings.configure_django(database_yaml=database_yaml_fn,
                                 config_name=config_name)

sys.argv.pop(1)
sys.argv.pop(1)

from scrapy.command.cmdline import execute
execute()
