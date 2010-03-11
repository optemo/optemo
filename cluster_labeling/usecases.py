#!/usr/bin/env python
import cluster_labeling.local_django_models as local
import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.text_handling as th

from django.db import models

class Usecase(local.LocalModel):
    class Meta:
        db_table='usecases'

    label = models.CharField(max_length=255, unique=True)
    indicator_words = models.ManyToManyField('IndicatorWord')

class IndicatorWord(local.LocalModel):
    class Meta:
        db_table='indicator_words'

    word = models.CharField(max_length=255, unique=True)

# This list also includes meta-features, for now.
usecases = [
    "Travel", "Fun", "Family photos", "Landscape/scenery",
    "Low light", "Outdoors", "Art", "Sports/action", "Video",
    "Wildlife", "Weddings", "Home", "Street",
    "Build quality", "Compact", "Clunky", "Image stabilization",
    "Viewfinder", "Manual control", "LCD"
    ]

def populate_usecases_and_indicator_words():
    Usecase.drop_table_if_exists()
    IndicatorWord.drop_table_if_exists()

    Usecase.create_table()
    IndicatorWord.create_table()

    for usecase_label in usecases:
        usecase = Usecase(label=usecase_label)
        usecase.save()
        
        indicator_words = th.get_words_from_string(usecase_label)
        iw_qs = IndicatorWord.get_manager()\
                .filter('word__in' = indicator_words)
        indicator_words = set(indicator_words)

        for iw in iw_qs:
            usecase.indicator_words.add(iw)
            indicator_words -= set([iw.word])

        for word in indicator_words:
            usecase.indicator_words.create(word=word)

        usecase.save()
