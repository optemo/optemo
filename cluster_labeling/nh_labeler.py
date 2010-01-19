#!/usr/bin/env python
import os
import sqlite3

from django.conf import settings

os.chdir('/optemo/site')

try:
    settings.configure(DATABASE_ENGINE='mysql',
                       DATABASE_NAME='optemo_development',
                       DATABASE_USER='nimalan',
                       DATABASE_PASSWORD='bobobo',
                       DATABASE_HOST='jaguar')
except(RuntimeError):
    pass

import cluster_labeling.optemo_django_models as optemo

wordcount_filename = '/optemo/site/cluster_hierarchy_counts'
db = sqlite3.connect(wordcount_filename)

# Create table
common_table_cols = \
    {
    "cluster_id" : "integer",
    "parent_cluster_id" : "integer",
    "word" : "text",
    "count" : "integer",
    "numchildren" : "integer"
    }
def gen_create_count_table_sql(tablename, extracols = {}):
    table_cols = common_table_cols
    
    if extracols != {}:
        table_cols = list(table_cols.iteritems())
        table_cols = dict(table_cols.extend(extracols.iteritems()))

    return \
    "CREATE TABLE " + tablename + " " + \
    "(" + \
    ', '.join(map(lambda (k,v): ' '.join([k,v]),
                  table_cols.iteritems())) + \
    ", PRIMARY KEY (cluster_id, word), " + \
    "CONSTRAINT count_check CHECK (count > 0) " + \
    "CONSTRAINT numchildren_check CHECK (numchildren >= 0)" + \
    ")"

# At the leaf clusters,
# - wordcounts stores the number of a particular word found in all
#   reviews associated with the cluster.
# - prodcounts stores the number of a particular product associated
#   with the cluster that contain the word. This should be equal to 1,
#   since only one product is associated with each leaf cluster.
# - reviewcounts stores the number of reviews of a particular product
#   associated with the cluster that contain the word.
count_tables = ['wordcounts', 'prodcounts', 'reviewcounts']
def create_count_tables(db):
    c = db.cursor()
    for table in count_tables:
        c.execute(gen_create_count_table_sql(table))
    db.commit()
    c.close()

def drop_count_tables(db):
    c = db.cursor()
    for table in count_tables:
        c.execute("DROP TABLE " + table)
    db.commit()
    c.close()

def gen_insert_count_entry_sql(tablename):
    return \
    "INSERT INTO " + tablename + \
    "(cluster_id, parent_cluster_id, numchildren, word, count) " + \
    "VALUES (?, ?, ?, ?, ?)"

def add_count_entry(db, cluster_id, parent_cluster_id, numchildren,
                    word, count, tablename):
    c = db.cursor()

    try:
        c.execute(gen_insert_count_entry_sql(tablename),
                  (cluster_id, parent_cluster_id,
                   numchildren, word, count))
        db.commit()
        c.close()
    except sqlite3.IntegrityError:
        print "Integrity error: (cluster_id, word) == (%d, %s)" % \
              (cluster_id, word)
        
        import pdb
        pdb.set_trace()
        
        raise

def add_wordcount_entry(*args):
    args = list(args)
    args.append('wordcounts')
    add_count_entry(*args)

def add_prodcount_entry(*args):
    args = list(args)
    args.append('prodcounts')
    add_count_entry(*args)

def add_reviewcount_entry(*args):
    args = list(args)
    args.append('reviewcounts')
    add_count_entry(*args)

def gen_select_count_entry_sql(tablename):
    return \
    "SELECT count from " + tablename + \
    " WHERE cluster_id = ? AND word = ?"

def get_wc(db, tablename, cluster_id, word):
    c = db.cursor()
    c.execute(gen_select_count_entry_sql(tablename), (cluster_id, word))
    results = c.fetchall()
    c.close()

    wordcount = None

    if len(results) > 0:
        wordcount = results[0][0]
    
    return wordcount

def gen_sum_child_counts_sql(tablename):
    return \
    "SELECT word, SUM(count) from " + tablename + " " + \
    "WHERE parent_cluster_id = ? GROUP BY word"

def sum_child_cluster_counts(db,
                          cluster_id, parent_cluster_id,
                          numchildren, tablename):
    c = db.cursor()
    c.execute(gen_sum_child_counts_sql(tablename), (cluster_id,))

    while (1):
        row = c.fetchone()
        if row == None:
            break
        
        word, countsum = row[0:2]
        add_count_entry(db, cluster_id, parent_cluster_id,
                        numchildren, word, countsum, tablename)
        
    c.close()

def sum_child_cluster_wordcounts(*args):
    args = list(args)
    args.append('wordcounts')
    sum_child_cluster_counts(*args)

def sum_child_cluster_prodcounts(*args):
    args = list(args)
    args.append('prodcounts')
    sum_child_cluster_counts(*args)

def sum_child_cluster_reviewcounts(*args):
    args = list(args)
    args.append('reviewcounts')
    sum_child_cluster_counts(*args)

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

import nltk.stem.porter
stemmer = nltk.stem.porter.PorterStemmer()

def compute_wcs_for_review(content):
    wcs = {}
    
    # Use the Punkt sentence tokenizer and the Treebank word tokenizer
    # to get the words in the review. Perform part-of-speech tagging
    # to get rid of spurious tokens.
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

def compute_counts_for_product(product):
    reviews = product.get_reviews()
    wordcounts = \
        map(lambda r: compute_wordcounts_for_review(r.content),
            reviews)

    merged_wordcount = {}
    reviewcount = {}
    
    for wc in wordcounts:
        for word, count in wc.iteritems():
            merged_wordcount[word] = \
                merged_wordcount.get(word, 0) + count
            reviewcount[word] = \
                reviewcount.get(word, 0) + 1

    prodcount = dict(map(lambda k: (k, 1), reviewcount.keys()))

    return merged_wordcount, reviewcount, prodcount

def compute_counts_for_cluster(db, cluster):
    children = cluster.get_children()
    numchildren = children.count()
    
    if numchildren == 0:
        nodes = cluster.get_nodes()
        assert(nodes.count() == 1)

        product = nodes[0].get_product()
        wordcount, reviewcount, prodcount = \
            compute_counts_for_product(product)

        for (word, count) in wordcount.iteritems():
            add_wordcount_entry(db, cluster.id, cluster.parent_id,
                                0, word, count)
        for (word, count) in reviewcount.iteritems():
            add_reviewcount_entry(db, cluster.id, cluster.parent_id,
                                  0, word, count)
        for (word, count) in prodcount.iteritems():
            add_prodcount_entry(db, cluster.id, cluster.parent_id,
                                  0, word, count)
    else:
        map(lambda child: compute_counts_for_cluster(db, child),
            children)
        sum_child_cluster_wordcounts\
            (db, cluster.id, cluster.parent_id, numchildren)
        sum_child_cluster_reviewcounts\
            (db, cluster.id, cluster.parent_id, numchildren)
        sum_child_cluster_prodcounts\
            (db, cluster.id, cluster.parent_id, numchildren)
        
def compute_all_counts\
        (db, version=optemo.CameraCluster.get_latest_version()):
    # All tables should be recreated, otherwise the resulting counts
    # will not be valid.
    drop_count_tables(db)
    create_count_tables(db)
    
    # Get clusters just below the root.
    root_children = \
        optemo.CameraCluster.objects.filter \
        (parent_id=0, version=version)

    map(lambda child: compute_counts_for_cluster(db, child),
        root_children)
    sum_child_cluster_wordcounts(db, 0, -1, root_children.count())
    sum_child_cluster_reviewcounts(db, 0, -1, root_children.count())
    sum_child_cluster_prodcounts(db, 0, -1, root_children.count())
