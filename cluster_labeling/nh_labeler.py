#!/usr/bin/env python
from django.conf import settings

settings.configure(DATABASE_ENGINE='mysql',
                   DATABASE_NAME='optemo_development',
                   DATABASE_USER='nimalan',
                   DATABASE_PASSWORD='bobobo',
                   DATABASE_HOST='jaguar')
