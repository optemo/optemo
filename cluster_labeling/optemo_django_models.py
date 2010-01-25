#!/usr/bin/env python
from django.db import models
from django.db.models import Max

def raise_abstract_method_error():
    raise NotImplementedError('Abstract method should not be called')

class OptemoModel(models.Model):
    class Meta:
        abstract = True

    default_db = 'optemo'
    
    @classmethod
    def get_manager(cls):
        return cls.objects.using(cls.default_db)

class Cluster(OptemoModel):
    class Meta:
        abstract = True

    parent_id = models.IntegerField()
    version = models.IntegerField()
    layer = models.IntegerField()
    cluster_size = models.IntegerField()
    brand = models.CharField(max_length=255)

    def get_children(self):
        raise_abstract_method_error()

    def get_nodes(self):
        raise_abstract_method_error()

    def get_parent(self):
        raise_abstract_method_error()

    @classmethod
    def get_latest_version(cls):
        manager = cls.get_manager()
        return manager.aggregate(Max('version'))['version__max']

class CameraCluster(Cluster):
    class Meta:
        db_table = 'camera_clusters'

    def get_children(self):
        return CameraCluster.get_manager().filter(parent_id=self.id)

    def get_nodes(self):
        return CameraNode.get_manager().filter(cluster_id=self.id)

    def get_parent(self):
        return CameraCluster.get_manager().filter(id=self.parent_id)[0]

class Node(OptemoModel):
    class Meta:
        abstract = True

    cluster_id = models.IntegerField()
    product_id = models.IntegerField()
    brand = models.CharField(max_length=255)
    version = models.IntegerField()

    def get_cluster(self):
        raise_abstract_method_error()

    def get_product(self):
        raise_abstract_method_error()

class CameraNode(Node):
    class Meta:
        db_table = 'camera_nodes'
    
    def get_cluster(self):
        qs = CameraCluster.get_manager().filter(id=self.cluster_id)
        assert(qs.count() == 1)
        return qs[0]

    def get_product(self):
        qs = Camera.get_manager().filter(id=self.product_id)
        assert(qs.count() == 1)
        return qs[0]

class Camera(OptemoModel):
    class Meta:
        db_table = 'cameras'

    brand = models.CharField(max_length=255)
    model = models.CharField(max_length=255)
    slr = models.BooleanField()
    waterproof = models.BooleanField()
    averagereviewrating = models.FloatField()
    totalreviews = models.IntegerField()
    reviewtext = models.TextField()

    def get_clusters(self, version = CameraCluster.get_latest_version()):
        node_qs = CameraNode.get_manager().filter\
                  (product_id = self.id, version = version)
        cluster_ids = map(lambda n: n.cluster_id, node_qs)
        cluster_qs = CameraCluster.get_manager().filter\
                     (id__in=cluster_ids)

        return cluster_qs

    def get_reviews(self):
        return Review.get_manager().filter(product_id=self.id)

class Review(OptemoModel):
    class Meta:
        db_table = 'reviews'
    
    rating = models.IntegerField()
    helpfulvotes = models.IntegerField()
    totalvotes = models.IntegerField()
    content = models.TextField()
    summary = models.CharField(max_length=255)
    value_rating = models.FloatField()
    pros = models.TextField()
    cons = models.TextField()
    
    product_id = models.IntegerField()
