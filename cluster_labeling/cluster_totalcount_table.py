#!/usr/bin/env python
from django.db import models

from django.db.models import Sum
from django.db.models import F

import cluster_labeling.local_django_models as local

class ClusterTotalCount(local.LocalModel):
    class Meta:
        abstract = True
        unique_together = (("cluster_id", "version"))

    cluster_id = models.BigIntegerField(primary_key=True)
    parent_cluster_id = models.BigIntegerField()
    totalcount = models.BigIntegerField()
    numchildren = models.IntegerField()
    version = models.IntegerField()

    @classmethod
    def sum_child_cluster_totalcounts\
        (cls, cluster_id, parent_cluster_id, numchildren, version):
        qs = cls.get_manager().\
             filter(parent_cluster_id=cluster_id, version=version).\
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
                numchildren=numchildren, version=version)
        cluster_totalcount.save()

    @classmethod
    def increment_totalcount(cls, cluster_id, parent_cluster_id,
                             numclusterchildren, version, totalcount):
        kwargs = {"cluster_id" : cluster_id,
                  "parent_cluster_id" : parent_cluster_id,
                  "numchildren" : numclusterchildren,
                  "version" : version}
        qs = cls.get_manager().filter(**kwargs)

        assert(qs.count() <= 1)

        if qs.count() == 0:
            kwargs['totalcount'] = totalcount
            cluster_value = cls(**kwargs)
            cluster_value.save()
        else:
            cluster_value = qs[0]
            cluster_value.totalcount = F('totalcount') + totalcount
            cluster_value.save()

    @classmethod
    def get_value(cls, cluster_id, version):
        qs = cls.get_manager()\
             .filter(cluster_id=cluster_id, version=version)\
             .values('totalcount')

        numrows = qs.count()
        assert(numrows <= 1)

        if numrows == 0:
            return None
        else:
            return qs[0]['totalcount']

class ClusterWordTotalCount(ClusterTotalCount):
    class Meta:
        db_table = 'wordtotalcounts'
        unique_together = (("cluster_id", "version"))

class ClusterProdTotalCount(ClusterTotalCount):
    class Meta:
        db_table = 'prodtotalcounts'
        unique_together = (("cluster_id", "version"))

class ClusterReviewTotalCount(ClusterTotalCount):
    class Meta:
        db_table = 'reviewtotalcounts'
        unique_together = (("cluster_id", "version"))

