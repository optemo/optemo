import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.text_handling as th

import nltk.stem.porter
stemmer = nltk.stem.porter.PorterStemmer()

import cluster_labeling.local_django_models as local
from django.db import models
from django.db.models import F

class Word(local.LocalModel):
    class Meta:
        db_table='words'
    
    word = models.CharField(max_length=255, unique=True)
    stem = models.CharField(max_length=255)
    count = models.BigIntegerField()
    correction = models.CharField(max_length=255)

def populate_word_table():
    Word.drop_table_if_exists()
    Word.create_table()

    for review in optemo.CameraReview.get_manager():
        content = review.content
        words = th.get_words_from_string(content)

        for word in words:
            word_qs = Word.get_manager().filter(word=word)

            assert(word_qs.count() <= 1)

            if word_qs.count() == 1:
                ws = word_qs[0]
                ws.count = F('count') + 1
            else:
                stem = stemmer.stem(word)
                ws = Word(word=word, stem=stem, count=1)
            
            ws.save()
