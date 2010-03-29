#!/usr/bin/env python
from __future__ import division

import cluster_labeling.local_django_models as local
import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.text_handling as th

from django.db import models

class Usecase(local.LocalModel):
    class Meta:
        db_table = '%s_%s' % (optemo.product_type_tablename_prefix,
                              'usecases')

    label = models.CharField(max_length=255, unique=True)
    indicator_words = models.ManyToManyField('IndicatorWord')

class IndicatorWord(local.LocalModel):
    class Meta:
        db_table = '%s_%s' % (optemo.product_type_tablename_prefix,
                              'indicator_words')

    word = models.CharField(max_length=255, unique=True)

class UsecaseClusterScore(local.LocalModel):
    class Meta:
        db_table = '%s_%s' % (optemo.product_type_tablename_prefix,
                              'usecase_cluster_scores')

    usecase = models.ForeignKey(Usecase)
    score = models.FloatField()

    cluster_id = models.BigIntegerField()
    version = models.IntegerField()

# This list also includes meta-features, for now.
known_usecases = {
    optemo.Printer : [],
    optemo.Camera :
    ["Travel", "Fun", "Family photos", "Landscape/scenery",
     "Low light", "Outdoors", "Art", "Sports/action", "Video",
     "Wildlife", "Weddings", "Home", "Street",
     "Build quality", "Compact", "Clunky", "Image stabilization",
     "Viewfinder", "Manual control", "LCD"]}

def populate_usecases_and_indicator_words():
    Usecase.drop_table_if_exists()
    IndicatorWord.drop_table_if_exists()

    Usecase.create_table()
    IndicatorWord.create_table()

    for usecase_label in known_usecases[optemo.product_type]:
        usecase = Usecase(label=usecase_label)
        usecase.save()
        
        indicator_words = th.get_words_from_string(usecase_label)
        iw_qs = IndicatorWord.get_manager()\
                .filter(word__in=indicator_words)
        indicator_words = set(indicator_words)

        for iw in iw_qs:
            usecase.indicator_words.add(iw)
            indicator_words -= set([iw.word])

        for word in indicator_words:
            usecase.indicator_words.create(word=word)

        usecase.save()

import cluster_labeling.nh_chi_scorer as chi

def score_usecases_for_all_clusters\
        (version=optemo.product_cluster_type.get_latest_version()):
    clusters = optemo.product_cluster_type.get_manager()\
               .filter(version=version)

    for cluster in clusters:
        score_usecases_for_cluster(cluster)

def score_usecases_for_cluster(cluster):
    usecases = Usecase.get_manager()

    for usecase in usecases:
        score = score_usecase_for_cluster(cluster, usecase)

        kwargs = {'usecase':usecase, 'version':cluster.version,
                  'cluster_id':cluster.id}
        qs = UsecaseClusterScore.get_manager().filter(**kwargs)

        assert(qs.count() == 0)

        kwargs['score'] = score
        usecase_cluster_score = UsecaseClusterScore(**kwargs)
        usecase_cluster_score.save()

def score_usecase_for_cluster(cluster, usecase):
    # Get indicator words for usecase
    iwords = usecase.indicator_words.all()
    
    # Compute chi-squared score for all indicator words
    iword_scores = \
        map(lambda iw:
            chi.get_chi_squared_score\
            (cluster.id, cluster.version, iw.word),
            iwords)

    # Combine all chi-squared scores in a way that is not influenced
    # by the number of indicator words associated with the cluster
    # i.e. take the average:
    iword_scores = map(lambda s: 0 if s is None else s, iword_scores)
    score = sum(iword_scores) / len(iword_scores)

    return score