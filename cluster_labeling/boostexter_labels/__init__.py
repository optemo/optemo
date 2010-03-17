def train_boostexter_on_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        generate_names_file(cluster)
        generate_data_file(cluster)
        train_boostexter(cluster)
        
def make_boostexter_labels_for_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        make_boostexter_labels_for_cluster(cluster)
        
def save_combined_rules_for_all_clusters\
        (version = optemo.CameraCluster.get_latest_version()):
    qs = optemo.CameraCluster.get_manager().filter(version=version)
    for cluster in qs:
        save_combined_rules_for_cluster(cluster)
