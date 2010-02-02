#!/usr/bin/env python
# This is a spellchecker based on an article by Peter Norvig:
# http://norvig.com/spell-correct.html
import re

class PNSpellChecker():
    alphabet = 'abcdefghijklmnopqrstuvwxyz'
    nWords = None
    prior_count = 1

    def train(self, words):
        self.nWords = {}
        for w in words:
            self.nWords[w] = self.nWords.get(w, self.prior_count) + 1

    def edits1(self, word):
        splits     = [(word[:i], word[i:]) for i in range(len(word) + 1)]
        deletes    = [a + b[1:] for a, b in splits if b]
        transposes = [a + b[1] + b[0] + b[2:] for a, b in splits if len(b)>1]
        replaces   = [a + c + b[1:] for a, b in splits for c in self.alphabet if b]
        inserts    = [a + c + b     for a, b in splits for c in self.alphabet]
        return set(deletes + transposes + replaces + inserts)

    def known_edits2(self, word):
        return set(e2 for e1 in self.edits1(word) for e2 in self.edits1(e1) if e2 in self.nWords)

    def known(self, words):
        return set(w for w in words if w in self.nWords)

    def get_rank(self, word):
        return self.nWords.get(word, self.prior_count)

    def correct(self, word):
        candidates = self.known([word]) or self.known(self.edits1(word)) or self.known_edits2(word) or [word]
        return max(candidates, key=self.get_rank)
