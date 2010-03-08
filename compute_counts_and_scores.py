#!/usr/bin/env python
import os

os.chdir('/home/nimalan/site_optemo_dbs')
execfile('cluster_labeling/django_settings.py')
os.chdir('/home/nimalan/site_optemo_dbs')

import cluster_labeling.word_counts as wc
import cluster_labeling.nh_chi_scorer as chi
import cluster_labeling.nh_mi_scorer as mi

cluster_vers = [23, 24]

for ver in cluster_vers:
    print "ver[%d]: Computing all counts" % (ver)
    wc.compute_all_counts(ver)
    
    print "ver[%d]: Computing chi-squared scores" % (ver)
    chi.compute_all_chi_squared_scores(ver)

    print "ver[%d]: Computing MI scores" % (ver)
    mi.compute_all_MI_scores(ver)

    print "ver[%d]: Done\n" % (ver)

