import cluster_labeling.optemo_django_models as optemo

from . import training
from . import combined_rules
from . import labels

def train_boostexter_on_all_clusters\
        (version = optemo.product_cluster_type.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        training.generate_names_file(cluster)
        training.generate_data_file(cluster)
        training.train_boostexter(cluster)
        
def make_boostexter_labels_for_all_clusters\
        (version = optemo.product_cluster_type.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        labels.make_boostexter_labels_for_cluster(cluster)
        
def save_combined_rules_for_all_clusters\
        (version = optemo.product_cluster_type.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        combined_rules.save_combined_rules_for_cluster(cluster)
