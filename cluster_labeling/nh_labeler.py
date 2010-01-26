#!/usr/bin/env python
import os
import sqlite3

from django.conf import settings

os.chdir('/optemo/site')

import cluster_labeling.optemo_django_models as optemo

wordcount_filename = '/optemo/site/cluster_hierarchy_counts'
db = sqlite3.connect(wordcount_filename)

import cluster_count_table as cct
import cluster_totalcount_table as ctct

# At the leaf clusters,
# - wordcounts stores the number of a particular word found in all
#   reviews associated with the cluster.
# - prodcounts stores the number of a particular product associated
#   with the cluster that contain the word. This should be equal to 1,
#   since only one product is associated with each leaf cluster.
# - reviewcounts stores the number of reviews of a particular product
#   associated with the cluster that contain the word.
count_tables = [cct.ClusterProdCount, cct.ClusterWordCount,
                cct.ClusterReviewCount]
totalcount_tables = [ctct.ClusterProdTotalCount,
                     ctct.ClusterWordTotalCount,
                     ctct.ClusterReviewTotalCount]

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

def compute_wordcounts_for_review(content):
    wcs = {}
    
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

def compute_counts_for_cluster(cluster):
    children = cluster.get_children()
    numchildren = children.count()
    
    if numchildren == 0:
        nodes = cluster.get_nodes()
        assert(nodes.count() == 1)

        product = nodes[0].get_product()
        wordcount, reviewcount, prodcount = \
            compute_counts_for_product(product)

        map(lambda table, counts:
            table.add_values_from(cluster, counts),
            count_tables, [prodcount, wordcount, reviewcount])

        totalcounts_to_mod_values = [1]
        totalcounts_to_mod = [ctct.ClusterProdTotalCount]

        # Total counts for reviews and words only need to be added if
        # the product actually contains reviews.
        if wordcount != {}:
            totalcounts_to_mod_values.extend\
            ([sum(wordcount.itervalues()),
              product.get_reviews().count()])
            totalcounts_to_mod.extend([ctct.ClusterWordTotalCount,
                                       ctct.ClusterReviewTotalCount])

        map(lambda table, totalcount:
            table\
            (cluster_id = cluster.id,
             parent_cluster_id = cluster.parent_id,
             totalcount = totalcount, numchildren = 0).save(),
            totalcounts_to_mod, totalcounts_to_mod_values)
    else:
        map(lambda child: compute_counts_for_cluster(child),
            children)
        
        map(lambda table:
            table.sum_child_cluster_counts\
            (cluster.id, cluster.parent_id, numchildren),
            count_tables)
        map(lambda table:
            table.sum_child_cluster_totalcounts\
            (cluster.id, cluster.parent_id, numchildren),
            totalcount_tables)
        
def compute_all_counts\
        (version=optemo.CameraCluster.get_latest_version()):
    # All tables should be recreated, otherwise the resulting counts
    # will not be valid.
    map(lambda table: table.drop_table_if_exists(), count_tables)
    map(lambda table: table.drop_table_if_exists(), totalcount_tables)
    
    map(lambda table: table.create_table(), count_tables)
    map(lambda table: table.create_table(), totalcount_tables)
    
    # Get clusters just below the root.
    root_children = optemo.CameraCluster.get_root_children(version)

    map(lambda child: compute_counts_for_cluster(child),
        root_children)

    map(lambda table:
        table.sum_child_cluster_counts(0, -1, root_children.count()),
        count_tables)    
    map(lambda table:
        table.sum_child_cluster_totalcounts\
        (0, -1, root_children.count()),
        totalcount_tables)
