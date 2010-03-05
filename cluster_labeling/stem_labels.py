#!/usr/bin/env python
import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.text_handling as th

import nltk.stem.porter
stemmer = nltk.stem.porter.PorterStemmer()

import cluster_labeling.local_django_models as local
from django.db import models
from django.db import transaction
from django.db.models import F

class StemLabel(local.LocalModel):
    class Meta:
        db_table='stem_labels'
    
    label = models.CharField(max_length=255, unique=True)
    stem = models.CharField(max_length=255, unique=True)

class WordStem(local.LocalModel):
    class Meta:
        db_table='word_stems'
    
    word = models.CharField(max_length=255, unique=True)
    stem = models.CharField(max_length=255)
    count = models.BigIntegerField()

def populate_word_stem_table():
    WordStem.drop_table_if_exists()
    WordStem.create_table()

    for review in optemo.CameraReview.get_manager():
        content = review.content
        words = th.get_words_from_string(content)

        for word in words:
            word_qs = WordStem.get_manager().filter(word=word)

            assert(word_qs.count() <= 1)

            if word_qs.count() == 1:
                ws = word_qs[0]
                ws.count = F('count') + 1
            else:
                stem = stemmer.stem(word)
                ws = WordStem(word=word, stem=stem, count=1)
            
            ws.save()

def populate_stem_label_table():
    populate_word_stem_table()
    
    StemLabel.drop_table_if_exists()
    StemLabel.create_table()

    stem_qs = WordStem.get_manager().values('stem').distinct()
    for row in stem_qs:
        stem = row['stem']
        label = WordStem.get_manager().filter(stem=stem).order_by('-count')[0].word
        sl = StemLabel(stem=stem, label=label)
        sl.save()

def get_stem_label(word, throw_if_not_found=False):
    stem = stemmer.stem(word)
    qs = StemLabel.get_manager().filter(stem=stem)

    if qs.count() == 0:
        if throw_if_not_found:
            errstr = 'Stem label not found: word=%s, stem=%s' % (word, stem)
            raise Exception(errstr)
        else:
            return stem

    return qs[0].label
