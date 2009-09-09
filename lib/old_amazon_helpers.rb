module AmazonFeedScraper

  def interpret_special_features(p)
    sf = p.specialfeatures
    a = sf[3..-1].split('|') #Remove leading nv:
    features = {}
    a.map{|l| 
      c = l.split('^') 
      features[c[0]] = c[1]
    }
    p.ppm = features['Print Speed'].match(/\d+[.]?\d*/)[0] if features['Print Speed']
    p.ttp = features['First Page Output Time'].match(/\d+[.]?\d*/)[0] if features['First Page Output Time'] && features['First Page Output Time'].match(/\d+[.]?\d*/)
    if features['Resolution']
      tmp = features['Resolution'].match(/(\d,\d{3}|\d+) ?x?X? ?(\d,\d{3}|\d+)?/)[1,2].compact
      tmp*=2 if tmp.size == 1
      p.resolution = tmp.sort{|a,b| 
        a.gsub!(',','')
        b.gsub!(',','')
        a.to_i < b.to_i ? 1 : a.to_i > b.to_i ? -1 : 0
      }.join(' x ') 
      p.resolutionmax = p.resolution.split(' x ')[0]
    end # String drop down style
    p.duplex = features['Duplex Printing'] # String
    p.connectivity = features['Connectivity'] # String
    p.papersize = features['Paper Sizes Supported'] # String
    p.paperoutput = features['Standard Paper Output'].match(/(\d,\d{3}|\d+)/)[0] if features['Standard Paper Output'] #Numeric
    p.dimensions = features['Dimensions'] #Not parsed yet
    p.dutycycle = features['Maximum Duty Cycle'].match(/(\d{1,3}(,\d{3})+|\d+)/)[0].gsub(',','') if features['Maximum Duty Cycle']
    p.paperinput = features['Standard Paper Input'].match(/(\d,\d{3}|\d+)/)[0] if features['Standard Paper Input'] && features['Standard Paper Input'].match(/(\d,\d{3}|\d+)/) #Numeric
    #Parse out special features
    if !features['Special Features'].nil?
      if features['Special Features'] == "Duplex Printing"
        features['Special Features'] = nil
        p.duplex = "Yes" if p.duplex.nil?
      end
    end
    p.special = features['Special Features']
    p
  end

  def get_camera_attributes(camera)
    res = Amazon::Ecs.item_lookup(camera.asin, :response_group => 'ItemAttributes')
    sleep(1+rand()*30) #Be nice to Amazon
    r = res.first_item
    unless r.nil?
      camera.detailpageurl = r.get('detailpageurl')
      atts = r.search_and_convert('itemattributes')
      camera.batteriesincluded = atts.get('batteriesincluded')
      camera.batterydescription = atts.get('batterydescription')
      camera.binding = atts.get('binding')
      camera.brand = atts.get('brand')
      camera.connectivity = atts.get('connectivity')
      camera.digitalzoom = atts.get('digitalzoom') #in terms of x
      camera.displaysize = atts.get('displaysize') #in inches
      camera.ean = atts.get('ean')
      camera.feature = atts.get_array('feature').join("\n")
      camera.floppydiskdrivedescription = atts.get('floppydiskdrivedescription')
      camera.hasredeyereduction = atts.get('hasredeyereduction')
      camera.includedsoftware = atts.get('includedsoftware')
      camera.isautographed = atts.get('isautographed')
      camera.ismemorabilia = atts.get('ismemorabilia')
      camera.itemheight = atts.get('itemdimensions/height') #hundredths-inches
      camera.itemlength = atts.get('itemdimensions/length')
      camera.itemwidth = atts.get('itemdimensions/width')
      camera.itemweight = atts.get('itemdimensions/weight') #hundredths-pounds
      camera.label = atts.get('label')
      camera.listpriceint = atts.get('listprice/amount') #cents
      camera.listpricestr = atts.get('listprice/formattedprice')
      camera.manufacturer = atts.get('manufacturer')
      camera.maximumfocallength = atts.get('maximumfocallength') #mm
      camera.maximumresolution = atts.get('maximumresolution') #MP
      camera.minimumfocallength = atts.get('minimumfocallength') #mm
      camera.model = atts.get('model')
      camera.mpn = atts.get('mpn')
      camera.opticalzoom = atts.get('opticalzoom') #in terms of x
      camera.packageheight = atts.get('packagedimensions/height') #hundredths-inches
      camera.packagelength = atts.get('packagedimensions/length')
      camera.packagewidth = atts.get('packagedimensions/width')
      camera.packageweight = atts.get('packagedimensions/weight') #hundredths-pounds
      camera.productgroup = atts.get('productgroup')
      camera.publisher = atts.get('publisher')
      camera.releasedate = atts.get('releasedate')
      camera.specialfeatures = atts.get('specialfeatures')
      camera.studio = atts.get('studio')
      camera.title = atts.get('title')
    end

    #Lookup images
    res = Amazon::Ecs.item_lookup(camera.asin, :response_group => 'Images')
    sleep(1+rand()*30) #Be nice to Amazon
    r = res.first_item
    unless r.nil?
      camera.imagesurl = r.get('smallimage/url')
      camera.imagesheight = r.get('smallimage/height')
      camera.imageswidth = r.get('smallimage/width')
      camera.imagemurl = r.get('mediumimage/url')
      camera.imagemheight = r.get('mediumimage/height')
      camera.imagemwidth = r.get('mediumimage/width')
      camera.imagelurl = r.get('largeimage/url')
      camera.imagelheight = r.get('largeimage/height')
      camera.imagelwidth = r.get('largeimage/width')
    end
    
    camera = scrape_details(camera)
    
    camera.save!
  end
  

  def get_printer_attributes(p)
    res = Amazon::Ecs.item_lookup(p.asin, :response_group => 'ItemAttributes')
    sleep(1+rand()*30) #Be nice to Amazon
    r = res.first_item
    unless r.nil?
      p.detailpageurl = r.get('detailpageurl')
      atts = r.search_and_convert('itemattributes')
      p.binding = atts.get('binding')
      p.brand = atts.get('brand')
      p.color = atts.get('color')
      p.cpumanufacturer = atts.get('cpumanufacturer')
      p.cpuspeed = atts.get('cpuspeed')
      p.cputype = atts.get('cputype')
      p.displaysize = atts.get('displaysize') #in inches
      p.ean = atts.get('ean')
      p.feature = atts.get_array('feature').join("\n")
      p.graphicsmemorysize = atts.get('graphicsmemorysize') #in MB
      p.isautographed = atts.get('isautographed')
      p.ismemorabilia = atts.get('ismemorabilia')
      p.itemheight = atts.get('itemdimensions/height') #hundredths-inches
      p.itemlength = atts.get('itemdimensions/length')
      p.itemwidth = atts.get('itemdimensions/width')
      p.itemweight = atts.get('itemdimensions/weight') #hundredths-pounds
      p.label = atts.get('label')
      p.language = atts.get('languages/language/name')
      p.legaldisclaimer = atts.get('legaldisclaimer')
      p.listpriceint = atts.get('listprice/amount') #cents
      p.listpricestr = atts.get('listprice/formattedprice')
      p.manufacturer = atts.get('manufacturer')
      p.model = atts.get('model')
      p.modemdescription = atts.get('modemdescription')
      p.mpn = atts.get('mpn')
      p.nativeresolution = atts.get('nativeresolution')
      p.numberofitems = atts.get('numberofitems')
      p.packageheight = atts.get('packagedimensions/height') #hundredths-inches
      p.packagelength = atts.get('packagedimensions/length')
      p.packagewidth = atts.get('packagedimensions/width')
      p.packageweight = atts.get('packagedimensions/weight') #hundredths-pounds
      p.processorcount = atts.get('processorcount')
      p.productgroup = atts.get('productgroup')
      p.publisher = atts.get('publisher')
      p.specialfeatures = atts.get('specialfeatures')
      p = interpret_special_features(p) if p.specialfeatures
      p.studio = atts.get('studio')
      p.systemmemorysize = atts.get('systemmemorysize')
      p.systemmemorytype = atts.get('systemmemorytype')
      p.title = atts.get('title')
      p.warranty = atts.get('warranty')
    
      #Lookup images
      res = Amazon::Ecs.item_lookup(p.asin, :response_group => 'Images')
      sleep(1+rand()*30) #Be nice to Amazon
      r = res.first_item
      p.imagesurl = r.get('smallimage/url')
      p.imagesheight = r.get('smallimage/height')
      p.imageswidth = r.get('smallimage/width')
      p.imagemurl = r.get('mediumimage/url')
      p.imagemheight = r.get('mediumimage/height')
      p.imagemwidth = r.get('mediumimage/width')
      p.imagelurl = r.get('largeimage/url')
      p.imagelheight = r.get('largeimage/height')
      p.imagelwidth = r.get('largeimage/width')
    
      p = scrape_details(p)
    
      p.save!
    end
  end
end
