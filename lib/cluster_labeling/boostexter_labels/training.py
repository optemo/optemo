import cluster_labeling.optemo_django_models as optemo

from . import filepaths as fn
from . import fields

import re
import subprocess

def get_labels(cluster):
    return [cluster.id, cluster.parent_id]

def generate_names_file(cluster):
    filename = fn.get_names_filename(cluster)
    f = open(filename, 'w')

    labels = get_labels(cluster)
    f.write(', '.join(map(str, labels)) + '.\n')

    for fieldname, fielddesc in fields.boosting_fields[optemo.product_type]:
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

def generate_data_file(cluster):
    filename = fn.get_data_filename(cluster)
    f = open(filename, 'w')

    version = cluster.version

    products_this = map(lambda x: (x.product, cluster.id),
                       cluster.get_nodes())

    parent_cluster_nodes = None
    if cluster.parent_id == 0:
        clusters = optemo.product_cluster_type.get_manager()\
                   .filter(parent_id = 0, version=version)

        parent_cluster_nodes = []
        for parent_child_cluster in clusters:
            parent_cluster_nodes.extend(parent_child_cluster.get_nodes())
    else:
        parent_cluster = optemo.product_cluster_type.get_manager()\
                         .filter(id = cluster.parent_id)[0]
        parent_cluster_nodes = parent_cluster.get_nodes()

    products_parent = \
        filter(lambda x:
               cluster.id not in
                   set(map(lambda y: y.id, x.get_clusters(cluster.version))),
               map(lambda x: x.product, parent_cluster_nodes))
    
    products_parent = map(lambda x: (x, cluster.parent_id), products_parent)

    products = products_this
    products.extend(products_parent)
    
    for product, cluster_id in products:
        for fieldname, fielddesc in fields.boosting_fields[optemo.product_type]:
            fieldval = product.__getattribute__(fieldname)

            if fielddesc == ['True', 'False']:
                if fieldval == '1' or fieldval == 'True':
                    fieldval = 'True'
                else:
                    fieldval = 'False'
            elif fieldval == None:
                fieldval = '?' # unknown value

            fieldval = re.sub(u'([-:,&]|#)', ' ', unicode(fieldval), re.UNICODE)
            fieldval = re.sub(u'(\w+)\.(\D|$)', r'\1 \2', unicode(fieldval), re.UNICODE)

            f.write(fieldval.encode('utf-8') + ', ')

        f.write(str(cluster_id) + '.\n')

def train_boostexter(cluster):
    # See the boosexter README for description of commands
    boostexter_prog = fn.boostexter_subdir + 'boostexter'
    boostexter_args = [
        '-n', str(40), # numrounds 
        '-W', str(2), # ngram_maxlen
        '-N', 'ngram', # ngram_type
        '-S', fn.get_filename_stem(cluster) # 'filename_stem'
        ]

    cmd = [boostexter_prog]
    cmd.extend(boostexter_args)

    proc = subprocess.Popen(cmd)
    retcode = proc.wait()
    assert(retcode == 0)
