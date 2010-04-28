# Scrapy settings for synscrape project
#
# For simplicity, this file contains only the most important settings by
# default. All the other settings are documented here:
#
#     http://doc.scrapy.org/topics/settings.html
#
# Or you can copy and paste them from where they're defined in Scrapy:
# 
#     scrapy/conf/default_settings.py
#

BOT_NAME = 'synscrape'
BOT_VERSION = '1.0'

SPIDER_MODULES = ['synscrape.spiders']
NEWSPIDER_MODULE = 'synscrape.spiders'
DEFAULT_ITEM_CLASS = 'synscrape.items.WordSenseItem'
ITEM_PIPELINES = ['synscrape.pipelines.DjangoWriterPipeline']

USER_AGENT = '%s/%s' % (BOT_NAME, BOT_VERSION)
