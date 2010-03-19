#!/usr/bin/env python
import nltk.stem.porter
stemmer = nltk.stem.porter.PorterStemmer()

import cluster_labeling.local_django_models as local
from django.db import models

import cluster_labeling.words as words

class StemLabel(local.LocalModel):
    class Meta:
        db_table='stem_labels'
    
    label = models.CharField(max_length=255, unique=True)
    stem = models.CharField(max_length=255, unique=True)

def populate_stem_label_table():
    words.populate_word_table()
    
    StemLabel.drop_table_if_exists()
    StemLabel.create_table()

    stem_qs = words.Word.get_manager().values('stem').distinct()
    for row in stem_qs:
        stem = row['stem']
        label = words.Word.get_manager().filter(stem=stem).order_by('-count')[0].word
        sl = StemLabel(stem=stem, label=label)
        sl.save()

stem_label_cache = {}
def get_stem_label(word, throw_if_not_found=False):
    stem = stemmer.stem(word)

    if stem in stem_label_cache:
        return stem_label_cache[stem]

    qs = StemLabel.get_manager().filter(stem=stem)
    assert(qs.count() <= 1)

    if qs.count() == 0:
        if throw_if_not_found:
            errstr = 'Stem label not found: word=%s, stem=%s' % (word, stem)
            raise Exception(errstr)
        else:
            return stem

    stem_label = qs[0].label
    stem_label_cache[stem] = stem_label
    return stem_label

