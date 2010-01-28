#!/usr/bin/env python
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
