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
        else:
            sndx += 'z' # unknown kind of character (i.e. number)

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

    def train(self, words):
        for w in words:
            w = w.lower()
            self.nWords[w] = self.nWords.get(w, self.prior_count) + 1

    def edits1(self, word):
        splits     = [(word[:i], word[i:]) for i in range(len(word) + 1)]
        deletes    = [a + '\0' + b[1:] for a, b in splits if b and b[0].islower()]
        transposes = [a + b[1] + b[0] + b[2:] for a, b in splits if len(b)>1]
        replaces   = [a + c + b[1:] for a, b in splits for c in self.alphabet if b and b[0].islower()]
        inserts    = [a + c.upper() + b for a, b in splits for c in self.alphabet]
        return set(deletes + transposes + replaces + inserts)

    def known_edits2(self, word):
        return set(e2
                   for e1 in self.edits1(word)
                   for e2 in self.edits1(e1)
                   if re.sub('\0', '', e2.lower()) in self.nWords)

    def known(self, words):
        return set(w for w in words if re.sub('\0', '', w.lower()) in self.nWords)

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
        
        candidates = [word]
        candidates.extend(self.known(self.edits1(word)))
        candidates.extend(self.known_edits2(word))

        change_scores = map(lambda c:
                            self.compute_change_score(word, c),
                            candidates)

        # Turn change scores into ~p(w | c), unnormalized.
        # This basically amounts to finding a way to make large change
        # scores become low unnormalized probabilties and to make
        # small change scores become high unnormalized probabilities.
        change_score_ceil = max(change_scores) * 1.1
        change_scores = map(lambda s: (change_score_ceil - s)**2,
                            change_scores)

        change_scores = zip(candidates, change_scores)

        change_score_dict = {}
        for (c, s) in change_scores:
            c = re.sub('\0', '', c.lower())
            change_score_dict[c] = change_score_dict.get(c, 0) + s

        for c, s in change_score_dict.iteritems():
            change_score_dict[c] *= math.sqrt(self.nWords.get(c, self.prior_count))

        return max(change_score_dict.iteritems(),
                   key=operator.itemgetter(1))[0]

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
