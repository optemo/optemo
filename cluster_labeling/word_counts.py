#!/usr/bin/env python
import cluster_labeling.optemo_django_models as optemo

import cluster_labeling.cluster_count_table as cct
import cluster_labeling.cluster_totalcount_table as ctct

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

import cluster_labeling.stem_labels as stm
import cluster_labeling.text_handling as th

import cluster_labeling.pn_spellcheck as pnsc

def compute_wordcounts_for_review(content, spellchecker):
    words = th.get_words_from_string(content)

    # Perform spell-checking
    words = map(spellchecker.correct, words)

    # Perform stemming
    words = map(stm.get_stem_label, words)

    # Populate word counts
    wcs = {}
    for word in words:
        wcs[word] = wcs.get(word, 0) + 1

    return wcs

def compute_counts_for_product(product, spellchecker):
    reviews = product.get_reviews()
    wordcounts = \
        map(lambda r: compute_wordcounts_for_review(r.content, spellchecker),
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

def compute_counts_for_cluster(cluster, spellchecker):
    children = cluster.get_children()
    numchildren = children.count()
    
    if numchildren == 0:
        for product in cluster.get_products():
            wordcount, reviewcount, prodcount = \
                compute_counts_for_product(product, spellchecker)

            map(lambda table, counts:
                table.increment_values_from\
                (cluster.id, cluster.parent_id, numchildren, counts),
                count_tables, [prodcount, wordcount, reviewcount])

            totalcounts_to_mod_values = [1]
            totalcounts_to_mod = [ctct.ClusterProdTotalCount]

            # Total counts for reviews and words only need to be added
            # if the product actually contains reviews.
            if wordcount != {}:
                totalcounts_to_mod_values.extend\
                ([sum(wordcount.itervalues()),
                  product.get_reviews().count()])
                totalcounts_to_mod.extend\
                ([ctct.ClusterWordTotalCount,
                  ctct.ClusterReviewTotalCount])
                
            map(lambda table, totalcount:
                table.increment_totalcount\
                (cluster.id, cluster.parent_id, 0, totalcount),
                totalcounts_to_mod, totalcounts_to_mod_values)

    else:
        map(lambda child:
            compute_counts_for_cluster(child, spellchecker),
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
        (version=optemo.CameraCluster.get_latest_version(),
         spellchecker = None):
    if spellchecker == None:
        spellchecker = \
            pnsc.PNSpellChecker.load_spellchecker(pnsc.default_spellchecker_fn)
    
    # Get clusters just below the root.
    root_children = optemo.CameraCluster.get_root_children(version)

    map(lambda child: compute_counts_for_cluster(child, spellchecker),
        root_children)

    map(lambda table:
        table.sum_child_cluster_counts(0, -1, root_children.count()),
        count_tables)    
    map(lambda table:
        table.sum_child_cluster_totalcounts\
        (0, -1, root_children.count()),
        totalcount_tables)

def drop_all_count_tables():
    map(lambda table: table.drop_table_if_exists(), count_tables)
    map(lambda table: table.drop_table_if_exists(), totalcount_tables)
    
    map(lambda table: table.create_table(), count_tables)
    map(lambda table: table.create_table(), totalcount_tables)
