#!/usr/bin/env python
import cluster_labeling.optemo_django_models as optemo
import subprocess

subdir = 'cc_boostexter_files/'

boosting_fields = {
    'title' : 'text',
    'brand' : 'text',
    'model' : 'text',
    
    'itemwidth' : 'continuous',
    'itemlength' : 'continuous',
    'itemheight' : 'continuous',
    'itemweight' : 'continuous',

    'opticalzoom' : 'continuous',
    'digitalzoom' : 'continuous',

    'slr' : ['True', 'False'],
    'waterproof' : ['True', 'False'],

    'maximumfocallength' : 'continuous',
    'minimumfocallength' : 'continuous',

    'batteriesincluded' : ['True', 'False'],

    'connectivity' : 'text',
    
    'hasredeyereduction' : ['True', 'False'],
    'includedsoftware' : 'text',

    'averagereviewrating' : 'continuous',
    'totalreviews' : 'continuous',

    'price' : 'continuous',
    'price_ca' : 'continuous',
    }

def get_labels(cluster):
    return [cluster.id, cluster.parent_id]

def generate_names_file(cluster):
    filestem = subdir + str(cluster.id)
    filename = filestem + ".names"
    f = open(filename, 'w')

    labels = get_labels(cluster)
    f.write(', '.join(map(str, labels)) + '.\n')

    for fieldname, fielddesc in boosting_fields.iteritems():
        f.write(fieldname + ": ")

        if type(fielddesc) == list:
            f.write(', '.join(map(str, fielddesc)) + '.')
        elif type(fielddesc) == str:
            f.write(fielddesc + '.')
        else:
            raise Exception("Invalid field desc type %s" %
                            (str(type(fielddesc))))

        f.write('\n')

    f.close()

def generate_data_file\
        (filestem,
         version = optemo.CameraCluster.get_latest_version()):
    pass

def train_boostexter():
    pass

def get_boostexter_rules():
    pass
