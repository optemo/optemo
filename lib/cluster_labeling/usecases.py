#!/usr/bin/env python
from __future__ import division

import cluster_labeling.local_django_models as local
import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.text_handling as th

import cluster_labeling.words as words

from django.db import models

class Usecase(local.LocalModel):
    class Meta:
        db_table = '%s_%s' % (optemo.product_type_tablename_prefix,
                              'usecases')

    label = models.CharField(max_length=255, unique=True)
    direct_indicator_words = \
        models.ManyToManyField\
        (words.Word, related_name='directly_indicated_usecases')
    indicator_words = \
        models.ManyToManyField\
        (words.Word, related_name='indicated_usecases')

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
    optemo.Printer : {},
    optemo.Camera :
    {"Travel" : [],
     "Fun" : [],
     "Family photos" : ["Family"],
     "Landscape/scenery" : [],
     "Low light" : ["Dim"],
     "Outdoors" : [],
     "Art" : [],
     "Sports/action" : ["Sports", "Action"],
     "Video" : [],
     "Wildlife" : [],
     "Weddings" : [],
     "Home" : [],
     "Street" : [],
     "Build quality" : [],
     "Compact" : [],
     "Clunky" : [],
     "Image stabilization" : ["Stabilization"],
     "Viewfinder" : [],
     "Manual control" : [],
     "LCD" : []}}

def populate_usecases():
    Usecase.drop_tables_if_exist()
    Usecase.create_tables()

    for (usecase_label, direct_indicator_words) in \
            known_usecases[optemo.product_type].iteritems():
        if len(direct_indicator_words) == 0:
            direct_indicator_words = th.get_words_from_string(usecase_label)
            
        usecase = Usecase(label=usecase_label)
        usecase.save()
        
        existing_words_qs, dne_word_entries = \
            words.Word.create_multiple_if_dne_and_return(direct_indicator_words)
        
        for word in existing_words_qs:
            usecase.direct_indicator_words.add(word)
        for word in dne_word_entries:
            word.save()
            usecase.direct_indicator_words.add(word)

        usecase.save()

def populate_indicator_words_for_usecases():
    for usecase in Usecase.get_manager():
        diws = usecase.direct_indicator_words

        for diw in diws.all():
            usecase.indicator_words.add(diw)

            for synonym in diw.get_all_synonyms():
                usecase.indicator_words.add(synonym)

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
