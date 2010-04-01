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

    default_count = 0
    
    word = models.CharField(max_length=255, unique=True)
    stem = models.CharField(max_length=255)
    count = models.BigIntegerField()
    correction = models.CharField(max_length=255, null=True,
                                  blank=True)

    @classmethod
    def create_if_dne_and_return(cls, word, count=None):
        if count == None: count = cls.default_count
        
        word_dne = None                
        word_qs = Word.get_manager().filter(word=word)
        
        if word_qs.count() == 0:
            word = Word(word=word,
                        stem=stemmer.stem(word), count=count)
            word_dne = True
        else:
            word = word_qs[0]
            word_dne = False

        return word, word_dne

    @classmethod
    def create_multiple_if_dne_and_return\
            (cls, words, count=None):
        if count == None: count = cls.default_count
        if len(words) == 0: return [], []
        
        existing_words_qs = Word.get_manager().filter(word__in=words)
        existing_words = set(map(lambda x: x['word'],
                                 existing_words_qs.values('word')))

        dne_word_entries = []
        dne_words = set(words) - existing_words
        for word in dne_words:
            dne_word_entries.append\
            (Word(word=word, stem=stemmer.stem(word), count=count))

        return existing_words_qs, dne_word_entries

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
        w_entry, w_entry_dne = \
            Word.create_if_dne_and_return(word, count)

        if not w_entry_created:
            w_entry.count = F('count') + count

        w_entry.save()

def populate_word_table():
    Word.drop_table_if_exists()
    Word.create_table()

    for review in optemo.Review.get_manager():
        populate_word_table_from_review(review)
