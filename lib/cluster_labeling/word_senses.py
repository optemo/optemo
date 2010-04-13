#!/usr/bin/env python
import cluster_labeling.local_django_models as local
from django.db import models

import cluster_labeling.words as words

POS_CHOICES = (
    ('N', 'noun'),
    ('V', 'verb'),
    ('J', 'adjective'),
    ('R', 'adverb')
)

pos_value_to_display = dict(POS_CHOICES)
pos_display_to_value = dict(map(lambda (x,y): (y,x), POS_CHOICES))

class WordSense(local.LocalModel):
    class Meta:
        db_table='word_senses'
        unique_together=(('word', 'name', 'definition'))
    
    word = models.ForeignKey(words.Word, related_name='sense_set')

    name = models.ForeignKey(words.Word, related_name='senses_namedby_set') # This needs a better name
    pos =  models.CharField(max_length=1, choices=POS_CHOICES)
    definition = models.CharField(max_length=255)

    synonyms = models.ManyToManyField\
               (words.Word, related_name='synonym_wordsense_set')
    antonyms = models.ManyToManyField\
               (words.Word, related_name='antonym_wordsense_set')

    notes = models.TextField(null=True)

    def __unicode__(self):
        return "(%s, %s)" % (self.name, self.get_pos_display())
