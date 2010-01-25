#!/usr/bin/env python
from django.db import models
from django.db import connections, transaction

from django.db.models import Sum

import cluster_labeling.local_django_models as local

class ClusterCount(local.LocalInsertOnlyModel):
    class Meta:
        abstract = True
        unique_together = (("cluster_id", "word"))

    cluster_id = models.BigIntegerField()
    parent_cluster_id = models.BigIntegerField()
    word = models.CharField(max_length=255)
    count = models.BigIntegerField()
    numchildren = models.IntegerField()

    @classmethod
    def sum_child_cluster_counts\
        (cls, cluster_id, parent_cluster_id, numchildren):
        qs = cls.objects.\
             filter(parent_cluster_id = cluster_id).\
             values('word').annotate(countsum=Sum('count'))

        for row in qs:
            word = row['word']
            countsum = row['countsum']

            cluster_count = \
                cls(cluster_id=cluster_id,
                    parent_cluster_id=parent_cluster_id,
                    word=word, count=countsum,
                    numchildren=numchildren)
            cluster_count.save()

    @classmethod
    def add_counts_from(cls, cluster, dict):
        numchildren = cluster.get_children().count()
        for (word, count) in dict.iteritems():
            cluster_count = \
                cls(cluster_id=cluster.id,
                    parent_cluster_id=cluster.parent_id,
                    word=word, count=count, numchildren=numchildren)
            cluster_count.save()

class ClusterWordCount(ClusterCount):
    class Meta:
        db_table = 'wordcounts'
        unique_together = (("cluster_id", "word"))

class ClusterProdCount(ClusterCount):
    class Meta:
        db_table = 'prodcounts'
        unique_together = (("cluster_id", "word"))

class ClusterReviewCount(ClusterCount):
    class Meta:
        db_table = 'reviewcounts'
        unique_together = (("cluster_id", "word"))
