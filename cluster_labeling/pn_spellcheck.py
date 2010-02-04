#!/usr/bin/env python
from __future__ import division

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
    fc = ''

    # translate alpha chars in name to soundex digits
    for c in name.upper():
        if c.isalpha():
            if not fc: fc = c   # remember first letter
            d = digits[ord(c)-ord('A')]
            sndx += d
        elif c == '\0':
            sndx += '\0'

    # replace first digit with first alpha character
    sndx = fc + sndx[1:]

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

class PNSpellChecker():
    alphabet = 'abcdefghijklmnopqrstuvwxyz'
    nWords = {}
    prior_count = 1

    cache = {}

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
            
            if len(e1) == len(e1_align) - 1:
                # This was a delete - need to remove the '\0's
                self.fill_edits_table(e2_table_add, e1, e1_align)
                e2_table_add = dict([(re.sub('\0', '', k), v) for k, v in
                                     e2_table_add.iteritems()])
            else:
                assert(len(e1) == len(e1_align))
                self.fill_edits_table(e2_table_add, e1, e1_align)

            e2_table.update(self.prune_unknown(e2_table_add))
        
        return e2_table

    def prune_unknown(self, etable):
        return dict([(k, v) for k, v in etable.iteritems() if k in self.nWords])

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

        if word[0] != candidate[0]:
            change_score += 8

        for i in xrange(1, len(word)):
            if word[i] == candidate[i]:
                continue

            if word[i] != '\0' and candidate[i] != '\0':
                if sndex_w[i] == sndex_c[i]:
                    change_score += 2
                else:
                    change_score += 4
            else:
                change_score += 1
        
        return change_score

    def correct(self, word):
        word = word.lower()

        if word in self.cache:
            return self.cache[word]

        candidates = {}
        candidates.update(self.known_edits2(word))
        candidates.update(self.prune_unknown(self.edits1(word)))
        candidates.update({word : word})

        candidates = \
            dict((k, self.compute_change_score(word, v))
                 for k, v in candidates.iteritems())

        # Turn change scores into ~p(w | c), unnormalized.
        # This basically amounts to finding a way to make large change
        # scores become low unnormalized probabilties and to make
        # small change scores become high unnormalized probabilities.
        change_score_ceil = \
            max([s for k, s in candidates.iteritems()]) * 1.1

        candidates = \
            dict([(k, ((change_score_ceil - s)**2) * \
                      math.sqrt(self.nWords.get(k, self.prior_count)))
                  for k, s in candidates.iteritems()])

        corr = max(candidates.iteritems(),
                   key=operator.itemgetter(1))[0]
        self.cache[word] = corr
        return corr

import cPickle
def save_spellchecker(schecker, fn):
    output_fn = open(fn, 'wb')
    cPickle.dump(schecker.nWords, output_fn)
    output_fn.close()

def load_spellchecker(fn):
    input_fn = open(fn, 'rb')
    nWords = cPickle.load(input_fn)
    input_fn.close()

    schecker = PNSpellChecker()
    schecker.nWords = nWords
    return schecker
