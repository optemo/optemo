#!/usr/bin/env python
import cluster_labeling.optemo_django_models as optemo

import nh_labeler as nh

import nltk.stem.porter
stemmer = nltk.stem.porter.PorterStemmer()

import cluster_labeling.local_django_models as local
from django.db import models
from django.db import transaction

class GlobalStem(local.LocalModel):
    class Meta:
        db_table='global_stems'
    
    word = models.CharField(max_length=255, unique=True)
    stem = models.CharField(max_length=255)

def build_global_stem_table\
        (version=optemo.CameraCluster.get_latest_version()):
    GlobalStem.drop_table_if_exists()
    GlobalStem.create_table()

    # Compute all stems
    qs = optemo.Review.get_manager().all()
    for review in qs:
        compute_global_stems_for_review(review)

    # Find the shortest word for each stem and make it the stem
    stem_qs = GlobalStem.get_manager().values('stem').distinct()
    for result in stem_qs:
        stem = result['stem']

        shortest_word = GlobalStem.get_manager().filter(stem=stem)
        shortest_word = \
            shortest_word.extra(select={'word_len':'length(word)'},
                                order_by=['word_len'])[0].word

        GlobalStem.get_manager().filter(stem=stem).update(stem=shortest_word)

@transaction.commit_on_success
def compute_global_stems_for_review(review):
    content = review.content
    words = nh.get_words_from_review(content)

    for word in words:
        if GlobalStem.get_manager().filter(word=word).count() > 0:
            continue

        stem = stemmer.stem(word)
        gs = GlobalStem(word=word, stem=stem)
        gs.save()

def stem(word):
    qs = GlobalStem.get_manager().filter(word=word)
    if qs.count() == 0:
        return word

    return qs[0].stem
