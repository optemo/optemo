output_subdir = 'cluster_labeling/cc_boostexter_files/'
boostexter_subdir = 'cluster_labeling/BoosTexter2_1/'

def get_names_filename(cluster):
    filestem = output_subdir + str(cluster.id)
    filename = filestem + ".names"
    return filename

def get_data_filename(cluster):
    filestem = output_subdir + str(cluster.id)
    filename = filestem + ".data"
    return filename

def get_strong_hypothesis_filename(cluster):
    filestem = output_subdir + str(cluster.id)
    filename = filestem + ".shyp"
    return filename    

