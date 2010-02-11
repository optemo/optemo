#!/usr/bin/env python
import cluster_labeling.optemo_django_models as optemo
import subprocess
import time

subdir = 'cc_boostexter_files/'

boosting_fields = [
    ('title', 'text'),
    ('brand', 'text'),
    ('model', 'text'),
    
    ('itemwidth', 'continuous'),
    ('itemlength', 'continuous'),
    ('itemheight', 'continuous'),
    ('itemweight', 'continuous'),

    ('opticalzoom', 'continuous'),
    ('digitalzoom', 'continuous'),

    ('slr', ['True', 'False']),
    ('waterproof', ['True', 'False']),

    ('maximumfocallength', 'continuous'),
    ('minimumfocallength', 'continuous'),

    ('batteriesincluded', ['True', 'False']),

    ('connectivity', 'text'),
    
    ('hasredeyereduction', ['True', 'False']),
    ('includedsoftware', 'text'),

    ('averagereviewrating', 'continuous'),
    ('totalreviews', 'continuous'),

    ('price', 'continuous'),
    ('price_ca', 'continuous')
    ]

def get_labels(cluster):
    return [cluster.id, cluster.parent_id]

def get_names_filename(cluster):
    filestem = subdir + str(cluster.id)
    filename = filestem + ".names"
    return filename

def generate_names_file(cluster):
    filename = get_names_filename(cluster)
    f = open(filename, 'w')

    labels = get_labels(cluster)
    f.write(', '.join(map(str, labels)) + '.\n')

    for fieldname, fielddesc in boosting_fields:
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

def get_data_filename(cluster):
    filestem = subdir + str(cluster.id)
    filename = filestem + ".data"
    return filename

def generate_data_file(cluster):
    filename = get_data_filename(cluster)
    f = open(filename, 'w')

    version = cluster.version

    parent_cluster = optemo.CameraCluster.get_manager()\
                     .filter(id = cluster.parent_id)[0]

    cameras_this = map(lambda x: x.get_product(), cluster.get_nodes())
    cameras_parent = \
        filter(lambda x:
               cluster.id not in
                   set(map(lambda y: y.id, x.get_clusters(cluster.version))),
               map(lambda x: x.get_product(),
                   parent_cluster.get_nodes()))
    
    cameras_this = map(lambda x: (x, cluster.id), cameras_this)
    cameras_parent = map(lambda x: (x, cluster.parent_id), cameras_parent)

    cameras = cameras_this
    cameras.extend(cameras_parent)
    
    for camera, cluster_id in cameras:
        f.write(', '.join([str(camera.__getattribute__(fieldname)) for fieldname, _ in boosting_fields]))
        f.write(', ')
        f.write(str(cluster_id) + '.\n')

def train_boostexter(cluster):
    # See the boosexter README for description of commands
    boostexter_prog = './BoosTexter2_1/boostexter'
    boostexter_args = {
        'numrounds' : ('-n', 10),
        'ngram_maxlen' : ('-W', 2),
        'ngram_type' : ('-N', 'ngram'),
        'filename_stem' : ('-S', subdir + str(cluster.id))
        }

    cmd = boostexter_prog + " " + \
          " ".join([arg[0] + " " + str(arg[1]) for opt, arg in
                    boostexter_args.iteritems()])

    proc = subprocess.Popen(cmd)
    retcode = proc.wait()
    assert(retcode == 0)

def get_boostexter_rules():
    pass
