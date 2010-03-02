#!/usr/bin/env python
import nltk.tokenize.punkt as punkt
import nltk.tokenize.treebank as treebank
sentence_tokenizer = punkt.PunktSentenceTokenizer()
word_tokenizer = treebank.TreebankWordTokenizer()

# From: http://www.daniweb.com/code/snippet216879.html#
def flatten(lst):
    for elem in lst:
        if type(elem) == list:
            for i in flatten(elem):
                yield i
        else:
            yield elem

spurious_pos = \
    ('TO', 'CC', '.', ':', 'DT', 'IN', 'PRP', ',',
     'EX', 'WRB', 'RP', 'CD', 'MD', '``', '$')

spurious_words = \
    ('br', '<')

def is_spurious_pos(postag):
    return postag in spurious_pos

import xml.sax.saxutils
def remove_html_escaping(content):
    return xml.sax.saxutils.unescape(content,
                                     {"&apos;" : "'", "&quot;" : '"'})

from nltk.corpus import stopwords
stopword_set = set(stopwords.words('english'))
stopword_set |= set(['br', '<', '"', '(', ')'])
def is_stopword(word):
    return word in stopword_set

import re
punct_re = re.compile('\W+')
number_re = re.compile('^\d+$')

def get_words_from_string(content):
    # Use the Punkt sentence tokenizer and the Treebank word tokenizer
    # to get the words in the review.
    words = map(word_tokenizer.tokenize,
                sentence_tokenizer.tokenize(remove_html_escaping(content)))
    
    # (Don't) perform part-of-speech tagging to get rid of spurious tokens.
    do_pos_based_elimination_of_spurious_tokens = False
    if do_pos_based_elimination_of_spurious_tokens:
        words = map(nltk.pos_tag, words)
        words = flatten(words)
        words = map(lambda (word, pos): word,
                    filter(lambda (word, pos): not is_spurious_pos(pos),
                           words))
    else:
        words = flatten(words)
    
    words = filter(lambda x: not is_stopword(x), words)
    words = map(lambda x: x.lower(), words)

    # Get rid of punctuation
    words_punct_split = []
    for word in words:
        splitwords = filter(lambda x: len(x) > 0, punct_re.split(word))
        words_punct_split.extend(splitwords)
    words = words_punct_split

    # Filter out everything is only 1 character long
    words = filter(lambda x: len(x) > 1, words)

    # Filter out everything that only consists of numbers
    words = filter(lambda x: not number_re.match(x), words)

    # Filter out everything that has as many or more numbers than
    # letters. This gets rid of a lot of model numbers.
    words = filter(lambda word:
                   reduce(lambda n, l: n + 1 if l.isalpha() else 0,
                          word, 0)
                   >
                   (len(word)/2),
                   words)
    return words
