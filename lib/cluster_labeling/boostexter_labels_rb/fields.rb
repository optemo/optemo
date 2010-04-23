module BtxtrLabels
  boosting_fields = \
  {
    Laptop => {
      'price' => ['continuous'],
      'brand' => ['text'],
      'hd' => ['continuous'],
      'ram' => ['continuous'],
      'screensize' => ['continuous']
    },
    
    Flooring => {
      'species_hardness' => ['continuous'],
      'width' => ['continuous'],
      'price' => ['continuous']
    },
    
    Printer => {
      'itemweight' => ['continuous'],
      'displaysize' => ['continuous'],
      
      'ppm' => ['continuous'],
      'ppmcolor' => ['continuous'],

      'resolutionarea' => ['continuous'],

      'paperinput' => ['continuous'],
      'paperoutput' => ['continuous'],

      'colorprinter' => [['True', 'False']],
      'scanner' => [['True', 'False']],
      'printserver' => [['True', 'False']],

      'averagereviewrating' => ['continuous'],
      'totalreviews' => ['continuous'],

      'price' => ['continuous']
    },
    
    Camera => {
      'itemweight' => ['continuous'],
      'displaysize' => ['continuous'],

      'opticalzoom' => ['continuous'],
      'digitalzoom' => ['continuous'],

      'maximumresolution' => ['continuous'],

      'maximumfocallength' => ['continuous'],
      'minimumfocallength' => ['continuous'],

      'averagereviewrating' => ['continuous'],
      'totalreviews' => ['continuous'],

      'price' => ['continuous']
    }
  }
end
