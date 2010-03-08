#!/usr/bin/env python
from __future__ import division
import enchant

import cluster_labeling.words as words

# This soundex implementation is taken from:
# http://code.activestate.com/recipes/52213/
# Modifications:
# - Does not skip adjacent soundex values that are the same.
# - No padding, no fixed length.
def soundex_mod(name):
    """ soundex module conforming to Knuth's algorithm
        implementation 2000-12-24 by Gregory Jorgensen
        public domain
    """

    # digits holds the soundex values for the alphabet
    digits = '01230120022455012623010202'
    sndx = ''
    fc = None

    # translate alpha chars in name to soundex digits
    for c in name.upper():
        if c.isalpha():
            if not fc: fc = c   # remember first letter
            d = digits[ord(c)-ord('A')]
            sndx += d
        elif c == '\0':
            sndx += '\0'
        else:
            sndx += 'z' # unknown kind of character (i.e. number)

    # replace first digit with first alpha character, unless there were no
    # alpha characters
    if fc:
        sndx = fc + sndx[1:]
    else:
        sndx = 'z' + sndx[1:]

    # return soundex code padded to len characters
    return sndx

# This is a spellchecker based on an article by Peter Norvig:
# http://norvig.com/spell-correct.html
# It is modified to give the cost of modifications based on the
# soundex algorithm. The soundex algorithm is for hashing English last
# names, but whatevs.
# It only deals with lowercase letters.
import re
import operator
import math

import cPickle

import cluster_labeling.text_handling as th
import cluster_labeling.camera_terms as camera_terms

class PNSpellChecker():
    alphabet = 'abcdefghijklmnopqrstuvwxyz'
    nWords = {}
    prior_count = 1

    cache = {}

    en_dict = enchant.Dict('en_US')

    def train(self, words):
        for w in words:
            w = w.lower()
            self.nWords[w] = self.nWords.get(w, self.prior_count) + 1

    def fill_edits_table(self, etable, word_unalign, word = None):
        if word == None:
            word = word_unalign
        
        splits = [(word[:i], word[i:]) for i in range(len(word) + 1)]
            
        deletes = [(a + b[1:], a + '\0' + b[1:]) for a, b in splits if b and b[0].islower()]
        etable.update(deletes)

        inserts = [(a + c + b, a + c.upper() + b) for a, b in splits for c in self.alphabet]
        etable.update(inserts)

        transposes = [a + b[1] + b[0] + b[2:] for a, b in splits if len(b)>1]
        transposes = zip(transposes, transposes)
        etable.update(transposes)
        
        replaces = [a + c + b[1:] for a, b in splits for c in self.alphabet if b and b[0].islower()]
        replaces = zip(replaces, replaces)
        etable.update(replaces)

        return etable

    def edits1(self, word):
        etable = {}
        self.fill_edits_table(etable, word)
        return etable

    def known_edits2(self, word):
        e1_table = self.edits1(word)

        e2_table = {}
        for (e1, e1_align) in e1_table.iteritems():
            e2_table_add = {}
                
            self.fill_edits_table(e2_table_add, e1, e1_align)
            e2_table_add = \
                dict([(re.sub('\0', '', k.lower()), v)
                      for (k, v ) in e2_table_add.iteritems()])

            e2_table.update(self.prune_unknown(e2_table_add))
        
        return e2_table

    def is_in_dictionary(self, word):
        if len(word) == 0:
            return False
        return PNSpellChecker.en_dict.check(word)

    def prune_non_dictionary_words(self, etable):
        return dict([(k, v) for k, v in etable.iteritems() if self.is_in_dictionary(k)])

    def is_known(self, word):
        return word in self.nWords or \
               word in camera_terms.known_terms or \
               self.is_in_dictionary(word)

    def prune_unknown(self, etable):
        return dict([(k, v) for k, v in etable.iteritems()
                     if self.is_known(k)])

    def compute_change_score(self, word, candidate):
        # Align the two words. This works because of the way that the
        # edits were done above.
        for i in xrange(0, len(candidate)):
            if not candidate[i].isupper():
                continue
            word = word[:i] + '\0' + word[i:]

        sndex_w = soundex_mod(word)
        sndex_c = soundex_mod(candidate)
        assert(len(sndex_w) == len(sndex_c))

        change_score = 0

        if sndex_w[0] != sndex_c[0]:
            change_score += 8

        for i in xrange(1, len(word)):
            if sndex_w[i] == sndex_c[i]:
                continue

            if sndex_w[i] != '\0' and sndex_c[i] != '\0':
                if sndex_w[i] == sndex_c[i]:
                    change_score += 2
                else:
                    change_score += 4
            elif (sndex_w[i] == '0' and sndex_c[i] == '\0') or \
                 (sndex_w[i] == '\0' and sndex_c[i] == '0'):
                change_score += 0.5 # Deletions of vowels is more okay
            else:
                change_score += 1

        return change_score

    def cache_correction(self, word, corr):
        self.cache[word] = corr

        word_qs = words.Word.get_manager().filter(word=word)
        assert(word_qs.count() <= 1)
        # If the word does not exist in the database, then don't
        # create a correction for it, because the countdata would be
        # null, making the entry not very useful.
        if word_qs.count() == 1:
            word_db = word_qs[0]
            word_db.correction = corr
            word_db.save()

    def correct(self, word):
        word = word.lower()

        if word in self.cache:
            return self.cache[word]

        word_qs = words.Word.get_manager().filter(word=word)
        assert(word_qs.count() <= 1)
        if word_qs.count() == 1:
            word_db = word_qs[0]
            if word_db.correction is not None:
                self.cache[word] = word
                return word_db.correction

        if word in camera_terms.known_terms or \
           self.is_in_dictionary(word):
            self.cache_correction(word, word)
            return word

        candidates = {}
        candidates.update(self.known_edits2(word))
        candidates.update(self.prune_unknown(self.edits1(word)))

        if len(candidates) == 0:
            self.cache_correction(word, word)
            return word

        candidates.update({word : word})

        candidates = \
            dict((k, self.compute_change_score(word, v))
                 for k, v in candidates.iteritems())

        # Turn change scores into ~p(w | c), unnormalized.
        # This basically amounts to finding a way to make large change
        # scores become low unnormalized probabilties and to make
        # small change scores become high unnormalized probabilities.
        change_score_ceil = \
            max([s for k, s in candidates.iteritems()])

        change_scores = \
            dict([(k, (change_score_ceil - s)**2)
                  for k, s in candidates.iteritems()])
        
        wordcounts = \
            dict([(k, math.sqrt(self.nWords.get(k, self.prior_count)))
                  for k, s in candidates.iteritems()])

        max_change_score = max(change_scores.itervalues())
        max_wordcount = max(wordcounts.itervalues())

        candidates = \
            dict([(k,
                   self.combine_scores(k, s, wordcounts,
                                       max_wordcount, max_change_score))
                  for k, s in change_scores.iteritems()])

        corr = max(candidates.iteritems(),
                   key=operator.itemgetter(1))[0]

        self.cache_correction(word, corr)
        return corr

    def combine_scores(self, candidate, score, wordcounts,
                       max_wordcount, max_change_score):
        combined_score = 1 * (1 if not th.is_stopword(candidate) else 0) + \
                         1 * (1 if self.is_in_dictionary(candidate) else 0) + \
                         1 * (wordcounts[candidate]/max_wordcount)
        
        if max_change_score == 0:
            return combined_score

        combined_score += 5 * (combined_score/max_change_score)
        return combined_score

    def save_spellchecker(self, fn):
        output_fn = open(fn, 'wb')
        cPickle.dump(self.nWords, output_fn)
        output_fn.close()
    
    @classmethod
    def load_spellchecker(cls, fn):
        input_fn = open(fn, 'rb')
        nWords = cPickle.load(input_fn)
        input_fn.close()

        schecker = PNSpellChecker()
        schecker.nWords = nWords
        return schecker

default_spellchecker_fn = 'cluster_labeling/spellchecker.pkl'

def train_spellchecker_on_reviews\
        (spellchecker_fn = default_spellchecker_fn):
    spellchecker = PNSpellChecker()

    i = 0

    content = ""
    for review in optemo.CameraReview.get_manager().all():
        i += 1
        content += " " + review.content

        print i, ": ", len(content)
        
        if len(content) > 2**20:
            words = th.get_words_from_string(content)
            spellchecker.train(words)
            content = ""

    words = th.get_words_from_string(content)
    spellchecker.train(words)

    spellchecker.save_spellchecker(spellchecker_fn)
