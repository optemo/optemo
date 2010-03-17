import cluster_labeling.optemo_django_models as optemo

import cluster_labeling.boostexter_labels.training as training
import cluster_labeling.boostexter_labels.combined_rules as combined_rules
import cluster_labeling.boostexter_labels.labels as labels

def train_boostexter_on_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        training.generate_names_file(cluster)
        training.generate_data_file(cluster)
        training.train_boostexter(cluster)
        
def make_boostexter_labels_for_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        labels.make_boostexter_labels_for_cluster(cluster)
        
def save_combined_rules_for_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        combined_rules.save_combined_rules_for_cluster(cluster)
