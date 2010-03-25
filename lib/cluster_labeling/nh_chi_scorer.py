#!/usr/bin/env python
from __future__ import division
import math

import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.cluster_score_table as cst

from cluster_labeling.score_utils import *

class ClusterChiSquaredScore(cst.ClusterScore):
    class Meta:
        db_table = \
            cst.ClusterScore.get_prefixed_table_name('chi_squared_scores')
        unique_together = (("cluster_id", "version", "word"))

def compute_chi_squared_score(N_UC, prior_count = 1):
    # Add prior counts to the probability distribution to avoid all of
    # the issues introduced by zeroes.
    N_UC += prior_count

    # Normalize
    Z = sum(N_UC)
    P_UC = N_UC / Z

    P_C = P_UC_to_P_C(P_UC)
    P_U = P_UC_to_P_U(P_UC)

    score = 0

    for et in [1, 0]:
        for ec in [1, 0]:
            N_uc = N_UC[et, ec]
            E_uc = Z * P_U[et] * P_C[ec]

            score += ((N_uc - E_uc)**2)/E_uc
            
    return score

def compute_chi_squared_score_for_word\
    (cluster_id, parent_cluster_id, version, word):
    N_UC = get_N_UC(cluster_id, parent_cluster_id, version, word)
    return compute_chi_squared_score(N_UC)

def compute_all_chi_squared_scores\
        (version=optemo.product_cluster_type.get_latest_version()):
    compute_all_scores(version, compute_chi_squared_score_for_word,
                       ClusterChiSquaredScore)

def get_chi_squared_score(cluster_id, version, word):
    kwargs = {'word':word, 'version':version, 'cluster_id':cluster_id}
    qs = ClusterChiSquaredScore.get_manager().filter(**kwargs)
    
    if qs.count() == 0:
        return None

    return qs[0].score
