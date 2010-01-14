#!/usr/bin/env python
from django.db import models

class Cluster(models.Model):
    class Meta:
        abstract = True

    parent_id = models.IntegerField()
    version = models.IntegerField()
    layer = models.IntegerField()
    cluster_size = models.IntegerField()
    brand = models.CharField(max_length=255)

    def get_children():
        pass

class CameraCluster(Cluster):
    class Meta:
        db_table = 'camera_clusters'

class Node(models.Model):
    pass

class Camera(models.Model):
    pass

class Review(models.Model):
    pass
