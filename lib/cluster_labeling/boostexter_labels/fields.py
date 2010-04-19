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
