#!/usr/bin/env python
from django.db import models
from django.db import connections, transaction

from django.db.models import Sum

import cluster_labeling.local_django_models as local

class ClusterTotalCount(local.LocalInsertOnlyModel):
    class Meta:
        abstract = True
        unique_together = (("cluster_id"))

    cluster_id = models.BigIntegerField(primary_key=True)
    parent_cluster_id = models.BigIntegerField()
    totalcount = models.BigIntegerField()
    numchildren = models.IntegerField()

    @classmethod
    def sum_child_cluster_totalcounts\
        (cls, cluster_id, parent_cluster_id, numchildren):
        qs = cls.objects.\
             filter(parent_cluster_id = cluster_id).\
             aggregate(totalcount_sum=Sum('totalcount'))

        totalcount_sum = qs['totalcount_sum']

        if totalcount_sum == None:
            # All of the cluster's children have zero entries. Zero
            # entries aren't stored in the table.
            return

        cluster_totalcount = \
            cls(cluster_id=cluster_id,
                parent_cluster_id=parent_cluster_id,
                totalcount=totalcount_sum,
                numchildren=numchildren)
        cluster_totalcount.save()

class ClusterWordTotalCount(ClusterTotalCount):
    class Meta:
        db_table = 'wordtotalcounts'

class ClusterProdTotalCount(ClusterTotalCount):
    class Meta:
        db_table = 'prodtotalcounts'

class ClusterReviewTotalCount(ClusterTotalCount):
    class Meta:
        db_table = 'reviewtotalcounts'
