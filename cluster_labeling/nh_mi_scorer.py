#!/usr/bin/env python
from __future__ import division

import math

import cluster_labeling.cluster_count_table as cct
import cluster_labeling.cluster_totalcount_table as ctct

import cluster_labeling.cluster_score_table as cst

def bin_to_int(idx):
    return int(idx, 2)

def get_MI_MLE_Pxx(cluster_id, word):
    count_table = cct.ClusterReviewCount
    totalcount_table = ctct.ClusterReviewTotalCount

    N = [0, 0, 0, 0]

    N[bin_to_int('11')] = count_table.get_value(cluster_id, word)
    N[bin_to_int('10')] = count_table.get_value(0, word) - N_11
    N[bin_to_int('01')] = \
        totalcount_table.get_value(cluster.id) - N_11
    N[bin_to_int('00')] = \
        totalcount_table.get_value(0) - N_01 - N_10 - N11

    return N

def compute_MI(N_UC, prior_count = 1):
    # Add prior counts to the probability distribution to avoid all of
    # the issues introduced by zeroes.
    N_UC = map(lambda x: x + prior_count, N_UC)

    # Normalize
    Z = sum(N_UC)
    P_UC = map(lambda x: x / Z, N_UC)
    
    # This method needs to handle inf values and division by zero.
    P_C = map(lambda probs: reduce(lambda x, y: x + y, probs),
              map(lambda vars: map(lambda var: P_UC[bin_to_int(var)],
                                   vars),
                  [['11', '01'], ['10', '00']]))

    P_U = map(lambda probs: reduce(lambda x, y: x + y, probs),
              map(lambda vars: map(lambda var: P_UC[bin_to_int(var)],
                                   vars),
                  [['11', '10'], ['01', '00']]))

    score = 0

    for et in [1, 0]:
        for ec in [1, 0]:
            p_uc = P_UC[bin_to_int(str(et) + str(ec))]
            score += p_uc * math.log(p_uc / (P_U[et] * P_C[ec]), 2)

    return score

def compute_MI_for_word(cluster_id, word):
    P_UC = get_MI_Pxx(cluster, word)
    return compute_MI(P_UC)

def compute_MI_scores_for_cluster(cluster_id):
    words = cct.ClusterReviewCount.get_words_for_cluster(cluster.id)
    miscores = dict(map(lambda word:
                        (word, compute_MI_for_word(cluster, word)),
                        words))
    
    cst.ClusterMIScore.add_values_from(miscores)

import cluster_labeling.optemo_django_models as optemo
def compute_all_MI_scores\
        (version=optemo.CameraCluster.get_latest_version()):
    # Drop/create the score table.
    cst.ClusterMIScore.drop_table_if_exists()
    cst.ClusterMIScore.create_table()
    
    # Recursively compute score for each word in each cluster and
    # store it in the score table.
    clusters_todo = []
    clusters_todo.extend(optemo.CameraCluster.get_root_children())

    while len(clusters_todo) > 0:
        curr_cluster = clusters_todo.pop()
        compute_MI_scores_for_cluster(curr_cluster.id)

        clusters_todo.extend(curr_cluster.get_children())

    compute_MI_scores_for_cluster(0)
