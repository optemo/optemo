#!/usr/bin/env python
from __future__ import division

import math

def bin_to_int(idx):
    return int(idx, 2)

def get_MI_MLE_Pxx(db, count_table, totalcount_table, cluster, word):
    count_table = count_tables[2] # reviewcounts
    totalcount_table = totalcount_tables[2] # reviewcounts_total

    N = [0, 0, 0, 0]

    N[bin_to_int('11')] = count_table.get_count(db, cluster.id, word)
    N[bin_to_int('10')] = count_table.get_count(db, 0, word) - N_11
    N[bin_to_int('01')] = \
        totalcount_table.get_totalcount(db, cluster.id) - N_11
    N[bin_to_int('00')] = \
        totalcount_table.get_totalcount(db, 0) - N_01 - N_10 - N11

    Z = sum(N)

    return tuple(map(lambda x: x / Z, N))

def compute_MI(P_UC):
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


def compute_MI_for_word(db, count_table, totalcount_table,
                        cluster, word):
    P_UC = get_MI_Pxx(db, cluster, word)
    return compute_MI(P_UC)

# The score table schema is:
# (parent_cluster_id, cluster_id, word, score).
def compute_MI_scores_for_cluster\
        (db, count_table, totalcount_table, cluster):
    pass

def compute_all_MI_scores\
        (db, scoretable, count_table, totalcount_table):
    # Drop/create the score table.
    # Recursively compute score for each word in each cluster and
    # store it in the score table.
    pass
