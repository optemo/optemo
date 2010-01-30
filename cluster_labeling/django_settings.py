#!/usr/bin/env python
import os

from django.conf import settings

os.chdir('/optemo/site')

wordcount_filename = '/optemo/site/cluster_hierarchy_counts'
local_sqlite3 = \
{
    'ENGINE' : 'django.db.backends.sqlite3',
    'NAME' : wordcount_filename,
    'TIMEOUT' : 30
}

optemo_mysql = \
{
    'ENGINE' : 'django.db.backends.mysql',
    'HOST' : 'jaguar',
    'NAME' : 'optemo_development',
    'USER' : 'nimalan',
    'PASSWORD' : 'bobobo'
}

try:
    settings.configure\
    (DATABASES = {
         'default' : optemo_mysql,
         'optemo' : optemo_mysql
      })

except(RuntimeError):
    print "RuntimeError occurred during django setup"
