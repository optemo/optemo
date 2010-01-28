#!/usr/bin/env python
import cluster_labeling.cluster_count_table as cct
import cluster_labeling.cluster_totalcount_table as ctct

def bin_to_int(idx):
    return int(idx, 2)

def get_N_UC(cluster_id, word):
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

def P_UC_to_P_C(P_UC):
    P_C = map(lambda probs: reduce(lambda x, y: x + y, probs),
              map(lambda vars: map(lambda var: P_UC[bin_to_int(var)],
                                   vars),
                  [['11', '01'], ['10', '00']]))
    return P_C

def P_UC_to_P_U(P_UC):
    P_U = map(lambda probs: reduce(lambda x, y: x + y, probs),
              map(lambda vars: map(lambda var: P_UC[bin_to_int(var)],
                                   vars),
                  [['11', '10'], ['01', '00']]))
    return P_U

def compute_scores_for_cluster(cluster_id, score_fn, score_table):
    words = cct.ClusterReviewCount.get_words_for_cluster(cluster_id)
    miscores = dict(map(lambda word: (word, score_fn(cluster, word)), words))
    
    score_table.add_values_from(miscores)

import cluster_labeling.optemo_django_models as optemo
def compute_all_scores\
        (version=optemo.CameraCluster.get_latest_version(), score_fn, score_table):
    # Drop/create the score table.
    score_table.drop_table_if_exists()
    score_table.create_table()
    
    # Recursively compute score for each word in each cluster and
    # store it in the score table.
    clusters_todo = []
    clusters_todo.extend(optemo.CameraCluster.get_root_children())

    while len(clusters_todo) > 0:
        curr_cluster = clusters_todo.pop()
        compute_scores_for_cluster(curr_cluster.id, score_fn, score_table)

        clusters_todo.extend(curr_cluster.get_children())

    compute_scores_for_cluster(0, score_fn, score_table)
