import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.text_handling as th

import nltk.stem.porter
stemmer = nltk.stem.porter.PorterStemmer()

import cluster_labeling.local_django_models as local
from django.db import models
from django.db import transaction
from django.db.models import F

class Word(local.LocalModel):
    class Meta:
        db_table='words'
    
    word = models.CharField(max_length=255, unique=True)
    stem = models.CharField(max_length=255)
    count = models.BigIntegerField()
    correction = models.CharField(max_length=255, null=True, blank=True)

@transaction.commit_on_success
def populate_word_table_from_review(review):
    content = review.content
    words = th.get_words_from_string(content)

    if not th.is_english(set(words)):
        return

    wc = {}
    for word in words:
        wc[word] = wc.get(word, 0) + 1

    for (word, count) in wc.iteritems():
        word_qs = Word.get_manager().filter(word=word)

        assert(word_qs.count() <= 1)

        w_entry = None
        
        if word_qs.count() == 1:
            w_entry = word_qs[0]
            w_entry.count = F('count') + count
        else:
            stem = stemmer.stem(word)
            w_entry = Word(word=word, stem=stem, count=count)

        w_entry.save()

def populate_word_table():
    Word.drop_table_if_exists()
    Word.create_table()

    for review in optemo.CameraReview.get_manager():
        populate_word_table_from_review(review)
