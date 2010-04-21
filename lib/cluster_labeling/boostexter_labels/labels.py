import cluster_labeling.optemo_django_models as optemo
import cluster_labeling.cluster_score_table as cst

from cluster_labeling.boostexter_labels.rules import *

def compute_weighted_average(cluster, fieldname, interval_set):
    filters = {"cameranode__cluster_id" : cluster.id,
               fieldname + "__isnull" : False}
 
    products = optemo.product_type.get_manager().filter(**filters)

    # It could be that all of the products have NULL values for the
    # field. There is nothing that can be said about whether the
    # cluster's products are low, average or high for this field.
    if products.count() == 0:
        return None

    Z = 0
    avg_w = 0

    for value in products.values(fieldname):
        value = value[fieldname]
        # Find interval that the value belongs in.
        idx = interval_binsearch(interval_set, value)
        weight = interval_set[idx][1]
        
        # Multiply value by the appropriate weight and add to avg.
        avg_w += weight * value
        Z += weight

    avg_w /= Z
    return avg_w

import math

def compute_parent_cluster_quartiles(cluster, fieldname):
    filters = None
    
    if cluster.parent_id == 0:
        version = cluster.version
        topcluster_ids = \
            map(lambda x: x['id'],
                optemo.product_cluster_type.get_manager().\
                filter(version=version, parent_id=0).values('id'))

        filters = {"%s__cluster_id__in" %
                   (product_node_type._meta.verbose_name) :
                   topcluster_ids}
    else:
        filters = {"%s__cluster_id" %
                   (product_node_type._meta.verbose_name) :
                   cluster.parent_id}

    filters[fieldname + "__isnull"] = False
    
    products = optemo.product_type.get_manager().filter(**filters)

    num_products = products.count()

    q_25 = int(math.floor(num_products/4))
    q_75 = int(math.floor(3*num_products/4))

    q_25 = products.order_by(fieldname).\
           values(fieldname)[q_25][fieldname]
    q_75 = products.order_by(fieldname).\
           values(fieldname)[q_75][fieldname]

    return q_25, q_75
