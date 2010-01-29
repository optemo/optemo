#!/usr/bin/env python
from django.db import models
import cluster_labeling.cluster_value_for_word_table as cvfwt

class ClusterScore(cvfwt.ClusterValueForWord):
    class Meta:
        abstract = True
        unique_together = (("cluster_id", "word"))

    value_name = "score"
    score = models.FloatField()

