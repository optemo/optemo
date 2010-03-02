#!/usr/bin/env python
import cluster_labeling.optemo_django_models as optemo

import nh_labeler as nh

import nltk.stem.porter
stemmer = nltk.stem.porter.PorterStemmer()

import cluster_labeling.local_django_models as local
from django.db import models
from django.db import transaction

class StemLabel(local.LocalModel):
    class Meta:
        db_table='stem_labels'
    
    label = models.CharField(max_length=255, unique=True)
    stem = models.CharField(max_length=255, unique=True)

def build_stem_label_table\
        (version=optemo.CameraCluster.get_latest_version()):
    StemLabel.drop_table_if_exists()
    StemLabel.create_table()

    # Compute all stem labels
    qs = optemo.Review.get_manager().all()
    for review in qs:
        compute_stem_labels_for_review(review)

@transaction.commit_on_success
def compute_stem_labels_for_review(review):
    content = review.content
    words = nh.get_words_from_review(content)

    for word in words:
        stem = stemmer.stem(word)
        qs = StemLabel.get_manager().filter(stem=stem)

        if qs.count() == 0:
            sl = StemLabel(label=word, stem=stem)
            sl.save()
            continue

        assert(qs.count() == 1)

        sl = qs[0]
        if len(sl.label) < len(word):
            continue

        sl.label = word
        sl.save()

def stem(word):
    stem = stemmer.stem(word)
    qs = StemLabel.get_manager().filter(stem=stem)
    if qs.count() == 0:
        return word

    return qs[0].label
