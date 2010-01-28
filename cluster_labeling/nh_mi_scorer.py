#!/usr/bin/env python
from __future__ import division

import math

import cluster_labeling.cluster_count_table as cct
import cluster_labeling.cluster_totalcount_table as ctct

import cluster_labeling.cluster_score_table as cst

from cluster_labeling.utils import *

def compute_MI(N_UC, prior_count = 1):
    # Add prior counts to the probability distribution to avoid all of
    # the issues introduced by zeroes.
    N_UC = map(lambda x: x + prior_count, N_UC)

    # Normalize
    Z = sum(N_UC)
    P_UC = map(lambda x: x / Z, N_UC)
    
    P_C = P_UC_to_P_C(P_UC)
    P_U = P_UC_to_P_U(P_UC)

    score = 0

    for et in [1, 0]:
        for ec in [1, 0]:
            p_uc = P_UC[bin_to_int(str(et) + str(ec))]
            score += p_uc * math.log(p_uc / (P_U[et] * P_C[ec]), 2)

    return score

def compute_MI_for_word(cluster_id, word):
    N_UC = get_N_UC(cluster, word)
    return compute_MI(N_UC)

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
