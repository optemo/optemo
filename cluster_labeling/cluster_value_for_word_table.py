#!/usr/bin/env python
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
    def add_values_from(cls, cluster, dict):
        numchildren = cluster.get_children().count()
        for (word, value) in dict.iteritems():
            kwargs = {"cluster_id" : cluster.id,
                      "parent_cluster_id" : cluster.parent_id,
                      "word": word, cls.value_name : value,
                      "numchildren" : numchildren}
            cluster_value = cls(**kwargs)
            cluster_value.save()
