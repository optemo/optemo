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
