import cluster_labeling.cluster_score_table as cst
class ClusterBoosTexterLabel(cst.ClusterScore):
    class Meta:
        db_table = 'boostexter_labels'
        unique_together = (("cluster_id", "version", "word"))

def compute_weighted_average(cluster, fieldname, interval_set):
    filters = {"cameranode__cluster_id" : cluster.id,
               fieldname + "__isnull" : False}
 
    products = optemo.Camera.get_manager().filter(**filters)

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
                optemo.CameraCluster.get_manager().\
                filter(version=version, parent_id=0).values('id'))

        filters = {"cameranode__cluster_id__in" : topcluster_ids}
    else:
        filters = {"cameranode__cluster_id" : cluster.parent_id}

    filters[fieldname + "__isnull"] = False
    
    products = optemo.Camera.get_manager().filter(**filters)

    num_products = products.count()

    q_25 = int(math.floor(num_products/4))
    q_75 = int(math.floor(3*num_products/4))

    q_25 = products.order_by(fieldname).\
           values(fieldname)[q_25][fieldname]
    q_75 = products.order_by(fieldname).\
           values(fieldname)[q_75][fieldname]

    return q_25, q_75

def make_label_for_rules_for_field(cluster, fieldname, rules):
    assert(all_rules_are_for_same_field(rules))

    rule_type = get_rule_type(rules[0])

    if rule_type == str(BoosTexterThresholdRule):
        return combine_threshold_rules(cluster, fieldname, rules)
    elif rule_type == str(BoosTexterSGramRule):
        return combine_sgram_rules(fieldname, rules)
    else:
        assert(False)

def make_labels_from_rules(cluster, rules):
    # Put all rules for a particular field together
    rules_a = gather_rules(rules)

    labels = []
    skipped_fields = []

    for (fieldname, rules_for_field) in rules_a.iteritems():
        maxweight, label = \
            make_label_for_rules_for_field\
            (cluster, fieldname, rules_for_field)

        if label is None:
            skipped_fields.append(fieldname)
        else:
            labels.append((maxweight, label))

    labels = map(lambda x: x[1], sorted(labels, key=lambda x: x[0])[::-1])
    return labels, skipped_fields

def save_combined_rules_for_cluster(cluster):
    rules = get_rules(cluster)
    save_combined_rules_from_rules(cluster, rules)

from django.db import transaction
@transaction.commit_on_success
def make_boostexter_labels_for_cluster(cluster):
    rules = get_rules(cluster)
    labels, _ = make_labels_from_rules(cluster, rules)

    numclusterchildren = cluster.get_children().count()

    version = cluster.version

    # Insert labels into database
    i = 0
    for label in labels:
        kwargs = {"cluster_id" : cluster.id,
                  "parent_cluster_id" : cluster.parent_id,
                  "word" : label, "score" : i,
                  "version" : version,
                  "numchildren" : numclusterchildren}
        boostexter_label = ClusterBoosTexterLabel(**kwargs)
        boostexter_label.save()
        
        i += 1

def make_boostexter_labels_for_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        make_boostexter_labels_for_cluster(cluster)
