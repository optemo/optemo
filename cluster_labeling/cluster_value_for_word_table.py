#!/usr/bin/env python
from django.db import models
from django.db import transaction

import cluster_labeling.local_django_models as local

class ClusterValueForWord(local.LocalInsertOnlyModel):
    class Meta:
        abstract = True
        unique_together = (("cluster_id", "word"))

    value_name = None

    cluster_id = models.BigIntegerField()
    parent_cluster_id = models.BigIntegerField()
    word = models.CharField(max_length=255)
    numchildren = models.IntegerField()

    @classmethod
    @transaction.commit_on_success
    def add_values_from(cls, cluster, dict):
        numchildren = cluster.get_children().count()
        for (word, value) in dict.iteritems():
            kwargs = {"cluster_id" : cluster.id,
                      "parent_cluster_id" : cluster.parent_id,
                      "word": word, cls.value_name : value,
                      "numchildren" : numchildren}
            cluster_value = cls(**kwargs)
            cluster_value.save()

    @classmethod
    def get_value(cls, cluster_id, word):
        qs = cls.get_manager().filter\
             (cluster_id = cluster_id, word = word).values(cls.value_name)

        numrows = qs.count()
        assert(numrows <= 1)

        if numrows == 0:
            return None
        else:
            return qs[0][cls.value_name]

    @classmethod
    def get_words_for_cluster(cls, cluster_id):
        qs = cls.get_manager().filter\
             (cluster_id = cluster_id).distinct().values('word')
        words = map(lambda x: x['word'], qs)
        return words
