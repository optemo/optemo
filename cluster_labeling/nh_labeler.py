#!/usr/bin/env python
import os
import sqlite3

from django.conf import settings

os.chdir('/optemo/site')
import cluster_labeling.optemo_django_models as optemo

try:
    settings.configure(DATABASE_ENGINE='mysql',
                       DATABASE_NAME='optemo_development',
                       DATABASE_USER='nimalan',
                       DATABASE_PASSWORD='bobobo',
                       DATABASE_HOST='jaguar')
except(RuntimeError):
    pass

wordcount_filename = '/optemo/site/cluster_hierarchy_wordcounts'
db = sqlite3.connect(wordcount_filename)

# Create table
wc_table_cols = \
    {
    "cluster_id" : "integer",
    "parent_cluster_id" : "integer",
    "word" : "text",
    "count" : "integer"
    }
create_wc_table_sql = \
    "CREATE TABLE wordcounts " + \
    "(" + \
    ', '.join(map(lambda (k,v): ' '.join([k,v]),
                  wc_table_cols.iteritems())) + \
    ", PRIMARY KEY (cluster_id, word), " + \
    "CONSTRAINT count_check CHECK (count > 0)" + \
    ")"

def create_wc_table(db):
    c = db.cursor()
    c.execute(create_wc_table_sql)
    db.commit()
    c.close()

def drop_wc_table(db):
    c = db.cursor()
    c.execute("DROP TABLE wordcounts")
    db.commit()
    c.close()

insert_wc_entry_sql = \
    "INSERT INTO wordcounts " + \
    "(cluster_id, word, count, parent_cluster_id) " + \
    "VALUES (?, ?, ?, ?)"
def add_wc_entry(db, cluster_id, parent_cluster_id, word, count):
    c = db.cursor()

    try:
        c.execute(insert_wc_entry_sql,
                  (cluster_id, word, count, parent_cluster_id))
        db.commit()
        c.close()
    except sqlite3.IntegrityError:
        print "Integrity error: (cluster_id, word) == (%d, %s)" % \
              (cluster_id, word)
        
        import pdb
        pdb.set_trace()
        
        raise

select_wc_sql = \
    "SELECT count from wordcounts WHERE cluster_id = ? AND word = ?"
def get_wc(db, cluster_id, word):
    c = db.cursor()
    c.execute(select_wc_sql, (cluster_id, word))
    results = c.fetchall()
    c.close()

    wordcount = None

    if len(results) > 0:
        wordcount = results[0][0]
    
    return wordcount

sum_child_wc_sql = \
    "SELECT word, SUM(count) from wordcounts " + \
    "WHERE parent_cluster_id = ? GROUP BY word"
def sum_child_cluster_wcs(db, parent_cluster_id, grandparent_cluster_id):
    c = db.cursor()
    c.execute(sum_child_wc_sql, (parent_cluster_id,))

    while (1):
        row = c.fetchone()
        if row == None:
            break
        
        word, countsum = row[0:2]
        add_wc_entry(db, parent_cluster_id, grandparent_cluster_id,
                     word, countsum)
        
    c.close()

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
stopword_set |= set(['br', '<', '"'])
def is_stopword(word):
    return word in stopword_set

import nltk.stem.porter
stemmer = nltk.stem.porter.PorterStemmer()

def compute_wcs_for_review(content):
    wcs = {}
    
    # Use the Punkt sentence tokenizer and the Treebank word tokenizer
    # to get the words in the review. Perform part-of-speech tagging
    # to get rid of spurious tokens.
    # Should probably also do word stemming?
    words = map(nltk.pos_tag,
                map(word_tokenizer.tokenize,
                    sentence_tokenizer.tokenize(remove_html_escaping(content))))
    words = flatten(words)
    words = map(lambda (word, pos): word,
                filter(lambda (word, pos): not is_spurious_pos(pos),
                       words))
    words = filter(lambda x: not is_stopword(x), words)

    for word in words:
        wcs[word] = wcs.get(word, 0) + 1

    # Create a map of stemmings and labels for stemmings
    stemmings = {}
    stemming_labels = {}
    for key in wcs.iterkeys():
        stemmed_key = stemmer.stem(key)

        if stemmed_key not in stemmings:
            stemmings[stemmed_key] = set()
            
        stemmings[stemmed_key].update([key])
        
        if (stemmed_key not in stemming_labels or
            len(key) < stemming_labels[stemmed_key]):
            stemming_labels[stemmed_key] = key

    # Create a stemmed wordcount
    wcs_stemmed = {}
    for (k,v) in stemmings.iteritems():
        wcs_stemmed[stemming_labels[k]] = sum(map(lambda x: wcs[x], v))

    return wcs_stemmed

