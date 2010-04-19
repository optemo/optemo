#!/usr/bin/env python
from django.db import models
from django.db.models import Max

def raise_abstract_method_error():
    raise NotImplementedError('Abstract method should not be called')

class OptemoModel(models.Model):
    class Meta:
        abstract = True

    default_db = 'optemo'
    
    @classmethod
    def get_manager(cls):
        return cls.objects.using(cls.default_db)

class Cluster(OptemoModel):
    class Meta:
        abstract = True

    parent_id = models.IntegerField()
    version = models.IntegerField()
    layer = models.IntegerField()
    cluster_size = models.IntegerField()
    brand = models.CharField(max_length=255)

    def get_products(self):
        raise_abstract_method_error()

    def get_children(self):
        raise_abstract_method_error()

    def get_nodes(self):
        raise_abstract_method_error()

    def get_parent(self):
        raise_abstract_method_error()

    @classmethod
    def get_latest_version(cls):
        manager = cls.get_manager()
        return manager.aggregate(Max('version'))['version__max']

    @classmethod
    def get_root_children(cls, version = None):
        if version == None:
            version = cls.get_latest_version()
            
        # Get clusters just below the root.
        root_children = \
            cls.get_manager().filter \
            (parent_id=0, version=version)

        return root_children

class FlooringCluster(Cluster):
    class Meta:
        db_table = 'flooring_clusters'

    def get_products(self):
        return Flooring.get_manager().filter(flooringnode__cluster__id=self.id)

    def get_children(self):
        return FlooringCluster.get_manager().filter(parent_id=self.id)

    def get_nodes(self):
        return FlooringNode.get_manager().filter(cluster_id=self.id)

    def get_parent(self):
        return FlooringCluster.get_manager().filter(id=self.parent_id)[0]

class PrinterCluster(Cluster):
    class Meta:
        db_table = 'printer_clusters'

    def get_products(self):
        return Printer.get_manager().filter(printernode__cluster__id=self.id)

    def get_children(self):
        return PrinterCluster.get_manager().filter(parent_id=self.id)

    def get_nodes(self):
        return PrinterNode.get_manager().filter(cluster_id=self.id)

    def get_parent(self):
        return PrinterCluster.get_manager().filter(id=self.parent_id)[0]

class CameraCluster(Cluster):
    class Meta:
        db_table = 'camera_clusters'

    def get_products(self):
        return Camera.get_manager().filter(cameranode__cluster__id=self.id)

    def get_children(self):
        return CameraCluster.get_manager().filter(parent_id=self.id)

    def get_nodes(self):
        return CameraNode.get_manager().filter(cluster_id=self.id)

    def get_parent(self):
        return CameraCluster.get_manager().filter(id=self.parent_id)[0]

class Product(OptemoModel):
    class Meta:
        abstract = True

    title = models.TextField()
    brand = models.CharField(max_length=255)
    model = models.CharField(max_length=255)

class Flooring(Product):
    class Meta:
        db_table = "floorings"

    species = models.TextField()
    feature = models.TextField()
    colorrange = models.TextField()

    width = models.FloatField()

    price = models.FloatField()

    warranty = models.CharField(max_length=255)

    thickness = models.FloatField()

    size = models.TextField()

    finish = models.CharField(max_length=255)

class Printer(Product):
    class Meta:
        db_table = "printers"

    displaysize = models.FloatField()

    itemwidth = models.IntegerField()
    itemlength = models.IntegerField()
    itemheight = models.IntegerField()
    itemweight = models.IntegerField()

    averagereviewrating = models.FloatField()
    totalreviews = models.IntegerField()

    price = models.IntegerField()
    price_ca = models.IntegerField()

    connectivity = models.CharField(max_length=255)

    feature = models.TextField()
    
    ppm = models.FloatField()
    ppmcolor = models.FloatField()
    ttp = models.FloatField() # thermal-transfer printing (?)

    duplex = models.CharField(max_length=255)

    resolutionarea = models.IntegerField()

    papersize = models.CharField(max_length=255)

    # Input/output tray sizes
    paperinput = models.IntegerField()
    paperoutput = models.IntegerField()

    special = models.CharField(max_length=255)
    platform = models.CharField(max_length=255)

    colorprinter = models.BooleanField()
    scanner = models.BooleanField()
    printserver = models.BooleanField()

    def get_clusters(self, version = PrinterCluster.get_latest_version()):
        node_qs = PrinterNode.get_manager().filter\
                  (product_id = self.id, version = version)
        cluster_ids = map(lambda n: n.cluster_id, node_qs)
        cluster_qs = PrinterCluster.get_manager().filter\
                     (id__in=cluster_ids)

        return cluster_qs

class Camera(Product):
    class Meta:
        db_table = 'cameras'

    displaysize = models.FloatField()

    itemwidth = models.IntegerField()
    itemlength = models.IntegerField()
    itemheight = models.IntegerField()
    itemweight = models.IntegerField()

    averagereviewrating = models.FloatField()
    totalreviews = models.IntegerField()

    price = models.IntegerField()
    price_ca = models.IntegerField()

    connectivity = models.CharField(max_length=255)

    opticalzoom = models.FloatField()
    digitalzoom = models.FloatField()

    maximumresolution = models.FloatField()

    slr = models.BooleanField()
    waterproof = models.BooleanField()

    maximumfocallength = models.FloatField()
    minimumfocallength = models.FloatField()

    batteriesincluded = models.BooleanField()

    hasredeyereduction = models.BooleanField()
    includedsoftware = models.CharField(max_length=255)

    def get_clusters(self, version = CameraCluster.get_latest_version()):
        node_qs = CameraNode.get_manager().filter\
                  (product_id = self.id, version = version)
        cluster_ids = map(lambda n: n.cluster_id, node_qs)
        cluster_qs = CameraCluster.get_manager().filter\
                     (id__in=cluster_ids)

        return cluster_qs

    def get_reviews(self):
        return CameraReview.get_manager().filter(product_id=self.id)

class Node(OptemoModel):
    class Meta:
        abstract = True

    cluster_id = models.IntegerField()
    product_id = models.IntegerField()
    brand = models.CharField(max_length=255)
    version = models.IntegerField()

class FlooringNode(Node):
    class Meta:
        db_table = 'flooring_nodes'

    cluster = models.ForeignKey(PrinterCluster)
    product = models.ForeignKey(Printer)

class PrinterNode(Node):
    class Meta:
        db_table = 'printer_nodes'

    cluster = models.ForeignKey(PrinterCluster)
    product = models.ForeignKey(Printer)

class CameraNode(Node):
    class Meta:
        db_table = 'camera_nodes'

    cluster = models.ForeignKey(CameraCluster)
    product = models.ForeignKey(Camera)

class Review(OptemoModel):
    class Meta:
        db_table = 'reviews'
    
    rating = models.IntegerField()
    helpfulvotes = models.IntegerField()
    totalvotes = models.IntegerField()
    content = models.TextField()
    summary = models.CharField(max_length=255)
    value_rating = models.FloatField()
    pros = models.TextField()
    cons = models.TextField()
    
    product_id = models.IntegerField()
    product_type = models.CharField(max_length=255)

class PrinterReview(Review):
    class Meta:
        proxy = True

    @classmethod
    def get_manager(cls):
        return Review.get_manager().filter(product_type='Printer')

class CameraReview(Review):
    class Meta:
        proxy = True

    @classmethod
    def get_manager(cls):
        return Review.get_manager().filter(product_type='Camera')

product_type = None

product_cluster_type = None
product_node_type = None
product_type = None

product_type_tablename_prefix = None

# pt_str should be either 'Camera', 'Printer' or 'Flooring'
def set_optemo_product_type(pt_str):
    global product_type
    global product_cluster_type
    global product_node_type
    global product_type
    global product_type_tablename_prefix
    
    product_type = pt_str
    
    product_cluster_type = eval('%sCluster' % product_type)
    product_node_type = eval('%sNode' % product_type)
    product_type = eval(product_type)

    product_type_tablename_prefix = product_type._meta.verbose_name
