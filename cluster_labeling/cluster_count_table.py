#!/usr/bin/env python
from django.db import models
from django.db.models import Max

from django.db import connections, transaction

from django.core.management.color import no_style

class LocalModel(models.Model):
    class Meta:
        abstract = True
        
    default_db = 'default'

    common_table_cols = None
    tablename = None

    @classmethod
    def get_manager(cls):
        return cls.objects.using(cls.default_db)

    @classmethod
    def get_db_conn(cls):
        return connections[cls.default_db]

    @classmethod
    def gen_create_table_sql(cls):
        return cls.get_db_conn().creation.sql_create_model(cls, no_style())[0][0]

    @classmethod
    @transaction.commit_on_success
    def create_table(cls):
        c = cls.get_db_conn().cursor()
        c.execute(cls.gen_create_table_sql())
        transaction.set_dirty()

    @classmethod
    def gen_drop_table_sql(cls):
        return cls.get_db_conn().creation.sql_destroy_model(cls, {}, no_style())[0]

    @classmethod
    @transaction.commit_on_success
    def drop_table(cls):
        c = cls.get_db_conn().cursor()
        c.execute(cls.gen_drop_table_sql())
        transaction.set_dirty()

    @classmethod
    @transaction.commit_on_success
    def drop_table_if_exists(cls):
        c = cls.get_db_conn().cursor()
        c.execute("DROP TABLE IF EXISTS %s" % (cls._meta.db_table))
        transaction.set_dirty()

class ClusterCount(LocalModel):
    class Meta:
        abstract = True
        unique_together = (("cluster_id", "word"))

    cluster_id = models.IntegerField()
    parent_cluster_id = models.IntegerField()
    word = models.CharField(max_length=255)
    count = models.IntegerField()
    numchildren = models.IntegerField()

    @classmethod
    def gen_sum_child_counts_sql(cls):
        return \
        "SELECT word, SUM(count) from " + cls.tablename + " " + \
        "WHERE parent_cluster_id = ? GROUP BY word"

    @classmethod
    def sum_child_cluster_counts\
            (cls, db, cluster_id, parent_cluster_id, numchildren):
        c = cls.get_db_conn().cursor()
        c.execute(cls.gen_sum_child_counts_sql(), (cluster_id,))

        while (1):
            row = c.fetchone()
            if row == None:
                break

            word, countsum = row[0:2]

            cluster_count = \
                cls(cluster_id=cluster_id,
                    parent_cluster_id=parent_cluster_id,
                    word=word, count=countsum,
                    numchildren=numchildren)
            cluster_count.save()

    @classmethod
    def add_counts_from(cls, db, cluster, dict):
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

class ClusterProdCount(ClusterCount):
    class Meta:
        db_table = 'prodcounts'

class ClusterReviewCount(ClusterCount):
    class Meta:
        db_table = 'reviewcounts'
