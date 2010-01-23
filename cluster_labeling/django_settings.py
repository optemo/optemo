#!/usr/bin/env python
import os

from django.conf import settings

os.chdir('/optemo/site')

wordcount_filename = '/optemo/site/cluster_hierarchy_counts'

try:
    settings.configure\
    (DATABASES = {
         'default' : {
            'ENGINE' : 'django.db.backends.sqlite3',
            'NAME' : wordcount_filename,
            'TIMEOUT' : 30
          },
         'optemo' : {
            'ENGINE' : 'django.db.backends.mysql',
            'HOST' : 'jaguar',
            'NAME' : 'optemo_development',
            'USER' : 'nimalan',
            'PASSWORD' : 'bobobo'
          }
      })

except(RuntimeError):
    print "RuntimeError occurred during django setup"
