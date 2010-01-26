#!/usr/bin/env python
from django.db import models
import cluster_labeling.cluster_value_for_word_table as cvfwt

from django.db.models import Sum

class ClusterCount(cvfwt.ClusterValueForWord):
    class Meta:
        abstract = True
        unique_together = (("cluster_id", "word"))

    value_name = "count"
    count = models.BigIntegerField()

    @classmethod
    def sum_child_cluster_counts\
        (cls, cluster_id, parent_cluster_id, numchildren):
        qs = cls.get_manager().\
             filter(parent_cluster_id = cluster_id).\
             values('word').annotate(count_sum=Sum('count'))

        for row in qs:
            word = row['word']
            count_sum = row['count_sum']

            cluster_count = \
                cls(cluster_id=cluster_id,
                    parent_cluster_id=parent_cluster_id,
                    word=word, count=count_sum,
                    numchildren=numchildren)
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
