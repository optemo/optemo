output_subdir = 'cluster_labeling/cc_boostexter_files/'
boostexter_subdir = 'cluster_labeling/BoosTexter2_1/'

def get_filename_stem(cluster):
    return output_subdir + \
           "%s_%s" % (optemo.product_type.verbose_name,
                      str(cluster.id))

def get_names_filename(cluster):
    filestem = get_filename_stem(cluster)
    filename = filestem + ".names"
    return filename

def get_data_filename(cluster):
    filestem = get_filename_stem(cluster)
    filename = filestem + ".data"
    return filename

def get_strong_hypothesis_filename(cluster):
    filestem = get_filename_stem(cluster)
    filename = filestem + ".shyp"
    return filename    

