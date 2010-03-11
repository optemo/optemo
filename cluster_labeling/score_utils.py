#!/usr/bin/env python
import cluster_labeling.cluster_count_table as cct
import cluster_labeling.cluster_totalcount_table as ctct

from numpy import *

def bin_to_int(idx):
    return int(idx, 2)

def get_N_UC(cluster_id, version, word):
    count_table = cct.ClusterReviewCount
    totalcount_table = ctct.ClusterReviewTotalCount

    N = zeros((2, 2))

    N[1, 1] = count_table.get_value(cluster_id, version, word)
    N[1, 0] = count_table.get_value(0, version, word) - N[1, 1]
    N[0, 1] = totalcount_table.get_value(cluster_id, version) - N[1, 1]
    N[0, 0] = totalcount_table.get_value(0, version) - N[0, 1] - N[1, 0] - N[1, 1]

    return N

def P_UC_to_P_C(P_UC):
    P_C = sum(P_UC, 0)
    return P_C

def P_UC_to_P_U(P_UC):
    P_U = sum(P_UC, 1)
    return P_U

def compute_scores_for_cluster(cluster_id, parent_cluster_id,
                               numchildren, version,
                               score_fn, score_table):
    words = cct.ClusterReviewCount\
            .get_words_for_cluster(cluster_id, version)
    miscores = dict(map(lambda word:
                        (word, score_fn(cluster_id, version, word)),
                        words))
    
    score_table.add_values_from(cluster_id, parent_cluster_id,
                                numchildren, version, miscores)

import cluster_labeling.optemo_django_models as optemo
def compute_all_scores(version, score_fn, score_table):
    # Drop/create the score table.
    score_table.drop_table_if_exists()
    score_table.create_table()
    
    # Recursively compute score for each word in each cluster and
    # store it in the score table.
    root_children = optemo.CameraCluster.get_root_children()

    clusters_todo = []
    clusters_todo.extend(root_children)

    compute_scores_for_cluster(0, -1, root_children.count(), version,
                               score_fn, score_table)

    while len(clusters_todo) > 0:
        curr_cluster = clusters_todo.pop()
        curr_cluster_children = curr_cluster.get_children()
        clusters_todo.extend(curr_cluster_children)

        compute_scores_for_cluster\
            (curr_cluster.id, curr_cluster.parent_id,
             curr_cluster_children.count(), version,
             score_fn, score_table)

