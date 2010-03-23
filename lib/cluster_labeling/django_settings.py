#!/usr/bin/env python
import os
import yaml

from django.conf import settings

def configure_django(**kwargs):
    database_yaml_fn = kwargs['database_yaml']
    config_name = kwargs['config_name']
    
    db_config = yaml.load(open(database_yaml_fn).read())[config_name]
    db_config = {
        'ENGINE' : 'django.db.backends.%s' % db_config['adapter'],
        'HOST' : db_config['host'],
        'NAME' : db_config['database'],
        'USER' : db_config['username'],
        'PASSWORD' : db_config['password']
        }

    try:
        settings.configure\
        (DATABASES = {
            'default' : db_config,
            'optemo' : db_config
            })
    except RuntimeError as e:
        print "RuntimeError occurred during django setup: %s", str(e)
        raise e
