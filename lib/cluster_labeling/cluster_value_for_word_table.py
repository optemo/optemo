#!/usr/bin/env python
from django.db import models
from django.db import transaction
from django.db.models import F

import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.local_django_models as local

class ClusterValueForWord(local.LocalModel):
    class Meta:
        abstract = True
        unique_together = (("cluster_id", "version", "word"))

    value_name = None

    cluster_id = models.BigIntegerField()
    parent_cluster_id = models.BigIntegerField()
    word = models.CharField(max_length=255)
    numchildren = models.IntegerField()

    # version is only needed because the top cluster has the same id,
    # 0, across all cluster hierarchies.
    version = models.IntegerField()

    @classmethod
    def get_prefixed_table_name(unprefixed_table_name):
        return '%s_%s' % \
               (optemo.product_type_tablename_prefix,
                unprefixed_table_name)

    @classmethod
    @transaction.commit_on_success
    def add_values_from(cls, cluster_id, parent_cluster_id,
                        numclusterchildren, version, dict):
        for (word, value) in dict.iteritems():
            kwargs = {"cluster_id" : cluster_id,
                      "parent_cluster_id" : parent_cluster_id,
                      "word": word, cls.value_name : value,
                      "numchildren" : numclusterchildren,
                      "version" : version}
            cluster_value = cls(**kwargs)
            cluster_value.save()

    @classmethod
    @transaction.commit_on_success
    def increment_values_from\
        (cls, cluster_id, parent_cluster_id,
         numclusterchildren, version, dict):
        for (word, value) in dict.iteritems():
            kwargs = {"cluster_id" : cluster_id,
                      "parent_cluster_id" : parent_cluster_id,
                      "word": word,
                      "numchildren" : numclusterchildren,
                      "version" : version}
            qs = cls.get_manager().filter(**kwargs)

            assert(qs.count() <= 1)

            if qs.count() == 0:
                kwargs[cls.value_name] = value
                cluster_value = cls(**kwargs)
                cluster_value.save()
            else:
                cluster_value = qs[0]
                cluster_value.__setattr__(cls.value_name, F(cls.value_name) + value)
                cluster_value.save()

    @classmethod
    def get_value(cls, cluster_id, version, word):
        qs = cls.get_manager()\
             .filter(cluster_id=cluster_id, version=version,
                     word=word)\
             .values(cls.value_name)

        numrows = qs.count()
        assert(numrows <= 1)

        if numrows == 0:
            return None
        else:
            return qs[0][cls.value_name]

    @classmethod
    def get_words_for_cluster(cls, cluster_id, version):
        qs = cls.get_manager()\
             .filter(cluster_id=cluster_id, version=version)\
             .distinct().values('word')
        words = map(lambda x: x['word'], qs)
        return words
