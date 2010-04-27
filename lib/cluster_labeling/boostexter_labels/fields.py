import cluster_labeling.optemo_django_models as optemo

from cluster_labeling.boostexter_labels import flooring_field_preprocessors as floor_fp

boosting_fields = \
{
    optemo.Laptop :
    {'price' : ['continuous'],
     'brand' : ['text'],
     'hd' : ['continuous'],
     'ram' : ['continuous'],
     'screensize' : ['continuous']},
    
    optemo.Flooring :
    {'species_hardness' : ['continuous'],
#      'species' :
#      ['text',
#       {'text_to_btxtr_fn' : floor_fp.species_to_btxtr,
#        'btxtr_to_text_fn' : floor_fp.flooring_field_from_btxtr}],
#      'feature' :
#      ['text',
#       {'text_to_btxtr_fn' : floor_fp.feature_to_btxtr,
#        'btxtr_to_text_fn' : floor_fp.flooring_field_from_btxtr}],
#      'colorrange' :
#      ['text',
#       {'text_to_btxtr_fn' : floor_fp.colorrange_to_btxtr,
#        'btxtr_to_text_fn' : floor_fp.flooring_field_from_btxtr}],
#      'finish' :
#      ['text',
#       {'text_to_btxtr_fn' : floor_fp.finish_to_btxtr,
#        'btxtr_to_text_fn' : floor_fp.flooring_field_from_btxtr}],
#      'warranty' :
#      ['text',
#       {'text_to_btxtr_fn' : floor_fp.warranty_to_btxtr,
#        'btxtr_to_text_fn' : floor_fp.flooring_field_from_btxtr}]

     'width' : ['continuous'],
#      'thickness' : ['continuous'], # Not cleaned properly

     'price' : ['continuous']},
    
    optemo.Printer :
    {'itemweight' : ['continuous'],

     'displaysize' : ['continuous'],

     'ppm' : ['continuous'],
     'ppmcolor' : ['continuous'],

     # These text fields are not easily usable because all punctuation
     # has to be removed from the field.
     # 'duplex' : ['text'],
     # 'papersize' : ['text'],
     # 'special' : ['text'],
     # 'platform' : ['text'],

     'resolutionarea' : ['continuous'],

     'paperinput' : ['continuous'],
     'paperoutput' : ['continuous'],

     'colorprinter' : [['True', 'False']],
     'scanner' : [['True', 'False']],
     'printserver' : [['True', 'False']],
     
     'averagereviewrating' : ['continuous'],
     'totalreviews' : ['continuous'],

     # 'price_ca' : ['continuous'],
     'price' : ['continuous']},

    
    optemo.Camera :
    {'itemweight' : ['continuous'],

     'displaysize' : ['continuous'],

     'opticalzoom' : ['continuous'],
     'digitalzoom' : ['continuous'],

     'maximumresolution' : ['continuous'],

     'maximumfocallength' : ['continuous'],
     'minimumfocallength' : ['continuous'],

     'averagereviewrating' : ['continuous'],
     'totalreviews' : ['continuous'],

     'price' : ['continuous'],
     'price_ca' : ['continuous']}}

fieldname_to_type = \
    dict(map(lambda (type, fields): (type, dict(fields)),
             boosting_fields.iteritems()))

boosting_fields_ordered = \
    dict(map(lambda (type, fields):
             (type, sorted(fields.iteritems(), key=lambda (k, v): k)),
             boosting_fields.iteritems()))
