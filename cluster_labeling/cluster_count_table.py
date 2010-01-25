#!/usr/bin/env python
from django.db import models
from django.db import connections, transaction

import cluster_labeling.local_django_models as local

class ClusterCount(local.LocalModel):
    class Meta:
        abstract = True
        unique_together = (("cluster_id", "word"))

    cluster_id = models.BigIntegerField()
    parent_cluster_id = models.BigIntegerField()
    word = models.CharField(max_length=255)
    count = models.BigIntegerField()
    numchildren = models.IntegerField()

    @classmethod
    def gen_sum_child_counts_sql(cls):
        return \
        "SELECT word, SUM(count) from " + cls._meta.db_table + " " + \
        "WHERE parent_cluster_id = %s GROUP BY word"

    @classmethod
    @transaction.commit_on_success
    def sum_child_cluster_counts\
            (cls, cluster_id, parent_cluster_id, numchildren):
        c = cls.get_db_conn().cursor()
        c.execute(cls.gen_sum_child_counts_sql(), [str(cluster_id)])

        transaction.set_dirty()

        # Using fetchone() and save()ing clustercounts concurrenctly
        # results in badness, possibly because the same cursor is
        # being used. Stupid Django..
        for row in c.fetchall():
            word, countsum = row[0:2]

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

    def save(self):
        LocalModel.save(self, force_insert=True)

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
