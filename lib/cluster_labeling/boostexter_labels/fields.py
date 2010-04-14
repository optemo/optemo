import cluster_labeling.optemo_django_models as optemo

boosting_fields = \
{
    optemo.Printer :
    [('itemweight', 'continuous'),

     ('displaysize', 'continuous'),

     ('ppm', 'continuous'),
     ('ppmcolor', 'continuous'),

     # These text fields are not easily usable because all punctuation
     # has to be removed from the field.
     # ('duplex', 'text'),
     # ('papersize', 'text'),
     # ('special', 'text'),
     # ('platform', 'text'),

     ('resolutionarea', 'continuous'),

     ('paperinput', 'continuous'),
     ('paperoutput', 'continuous'),

     ('colorprinter', ['True', 'False']),
     ('scanner', ['True', 'False']),
     ('printserver', ['True', 'False']),
     
     ('averagereviewrating', 'continuous'),
     ('totalreviews', 'continuous'),

     ('price', 'continuous')],
    # ('price_ca', 'continuous')],
    
    optemo.Camera :
    [('itemweight', 'continuous'),

     ('displaysize', 'continuous'),

     ('opticalzoom', 'continuous'),
     ('digitalzoom', 'continuous'),

     ('maximumresolution', 'continuous'),

     ('maximumfocallength', 'continuous'),
     ('minimumfocallength', 'continuous'),

     ('averagereviewrating', 'continuous'),
     ('totalreviews', 'continuous'),

     ('price', 'continuous'),
     ('price_ca', 'continuous')]}

fieldname_to_type = \
    dict(map(lambda (type, fields): (type, dict(fields)),
             boosting_fields.iteritems()))

fieldname_to_quality = {
    optemo.Printer :
    {
        'brand' : ('Brand'),
        'itemwidth' :
        ('Width', ['Thin', 'Average Width', 'Not Thin'], True),
        'itemlength' :
        ('Length', ['Narrow', 'Average Length', 'Long'], True),
        'itemheight' :
        ('Height', ['Short', 'Average Height', 'Tall'], True),
        'itemweight' :
        ('Weight', ['Lightweight', 'Average Weight', 'Heavy'], True),

        'displaysize' :
        ('Display Size', ['Small', 'Average', 'Large'], False),
    },
    
    optemo.Camera :
    {
        'brand' : ('Brand'),
        'itemwidth' :
        ('Width', ['Thin', 'Average Width', 'Not Thin'], True),
        'itemlength' :
        ('Length', ['Narrow', 'Average Length', 'Long'], True),
        'itemheight' :
        ('Height', ['Short', 'Average Height', 'Tall'], True),
        'itemweight' :
        ('Weight', ['Lightweight', 'Average Weight', 'Heavy'], True),

        'displaysize' :
        ('Display Size', ['Small', 'Average', 'Large'], False),

        'opticalzoom' :
        ('Optical Zoom', ['Low', 'Average', 'High'], False),
        'digitalzoom' :
        ('Digital Zoom', ['Low', 'Average', 'High'], False),

        'maximumresolution' :
        ('Resolution', ['Low', 'Average', 'High'], False),
    
        'slr' : ('SLR'),
        'waterproof' : ('waterproof'),

        'maximumfocallength' :
        ('Maximum Focal Length', ['Low', 'Average', 'High'], False),
        'minimumfocallength' :
        ('Minimum Focal Length', ['Low', 'Average', 'High'], False),

        'batteriesincluded' : ('Batteries Included'),

        'connectivity' : ('Connectivity'),

        'hasredeyereduction' : ('Has Red-Eye Reduction'),
        'includedsoftware' : ('Included Software'),
    
        'averagereviewrating' :
        ('Average Review Rating',
         ['Low Rating', 'Average Rating', 'Highly Rated'], True),
        'totalreviews' :
        ('Total Reviews',
         ['Few Reviews', 'Average Number of Reviews', 'Many Reviews'],
         True),

        'price' : ('Price', ['Low', 'Average', 'High'], False),
        'price_ca' : ('Price (CAD)', ['Low', 'Average', 'High'], False)}}
