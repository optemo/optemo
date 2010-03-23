#!/usr/bin/env python
import os

from django.conf import settings

os.chdir('/home/nimalan/site_optemo_dbs')

local_sqlite3 = \
{
    'ENGINE' : 'django.db.backends.sqlite3',
    'NAME' : wordcount_filename,
    'TIMEOUT' : 30
}

localhost_mysql = \
{
    'ENGINE' : 'django.db.backends.mysql',
    'HOST' : 'localhost',
    'NAME' : 'optemo_development',
    'USER' : 'nimalan',
    'PASSWORD' : 'bobobo'
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
