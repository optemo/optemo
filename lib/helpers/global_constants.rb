module Constants
  
  # The idea for ignore lists is that we don't copy over 
  # certain attributes because they're automatically generated
  # or because we don't want to. The ones which are auto-generated
  # are listed in the general ignore list:  
  $general_ignore_list = ['id','created_at','updated_at']
  
  # For internal use.
  $region_suffixes = {'CA' => '_ca', 'US' => ''}
  
  $ca = {'price'=>'price_ca', 'pricestr' => 'price_ca_str', 'bestoffer' => 'bestoffer_ca', 'instock'=> 'instock_ca','prefix' => 'CAD'}
  $us = {'price'=>'price', 'pricestr' => 'pricestr', 'bestoffer' => 'bestoffer', 'prefix' => '', 'instock'=> 'instock'}
    
  # The definitive list of brands...
  $printer_brands = ["3com", "Advantus", "Apple", "ASUS", "Belkin", "Brother", "Buddy", "Canon", \
     "Copystar", "Curtis Manufacturing", "Dell", "Elite", "Epson", "Fargo", "General Ribbon Corporation", \
    "Genicom", "Global Marketing Partners", "Hewlett-Packard", "HP", "IBM", "Infoprint Solutions",\
    'Kodak',"Konica", "Konica-Minolta", "Kyocera", 'Lanier', "Lenovo", "Lexmark", "Media science",\
    "Micro Innovations", "Minolta", "Oki Data", "Omni Mount", "Panasonic",\
    "Pitney Bowes", "Promedia", "QMS", "Ricoh", "Samsung", "Sharp", "Sunset", \
    "Tally", "Teac", "Tektronix", "Thorens", "Toshiba", "Xerox"]
  
  # Series: sometimes included in model names.
  $printer_series = ['imageclass','phaser','laserjet', 'laserwriter', 'oki', 'imagerunner', 'printer', 'printers', 'qms', \
    'estudio', 'optra', 'pro', 'officejet', 'workcentre', 'other', 'okifax', 'lanierfax', 'okipage',\
    'pixma', 'deskjet', 'stylus', 'docuprint', 'series','color', 'laser', 'printer','jet', 'business']

  $brand_alternatives = [ ['hp', 'hewlett packard', 'hewlett-packard'], \
    ['konica', 'konica-minolta', 'konica minolta'], ['okidata', 'oki data', 'oki'],\
     ['kyocera', 'kyocera mita'], ['infoprint solutions', 'infoprint'] ]

  $conditions = ['Refurbished', 'Remanufactured', 'OEM', 'Used', 'New']

  $float_rxp = /(\d+,)?\d+(\.\d+)?/

end

module CartridgeConstants
  
  $cartridge_conditions = ['Remanufactured', 'Refurbished', 'Compatible', 'OEM', 'Genuine', 'New']
  $cartridge_colors = ['Yellow', 'Cyan', 'Magenta', 'Black']
  $fake_brands = ["123inkjets", "4inkjets", "Best Deal Toner", "Digital Products", "G & G", \
      "General Ribbon Corporation", "Global Marketing Partners", "Ink It Up 4 Less", "Ink-Power",\
       "Inkers", "LD Products", "Mega Leader", "Mipo", "Pritop", "Q-Imaging", "Sophia Global", \
       "TNT Toner", "Cartridge Family" , 'Ink Grabber']  #"SIB", "SOL", "STC", ] <-- These are weird
end

module CameraConstants
  @@model = Camera
  @@scrapedmodel = ScrapedCamera
  @@brands = $camera_brands
  @@series = ['finepix']
  @@descriptors = ['super', 'duper']
end

module PrinterConstants
  @@model = Printer
  @@scrapedmodel = ScrapedPrinter
  @@brands = $printer_brands
  @@series = $printer_series
  @@descriptors = [/\smfp\s/i, /\smultifunct?ion\s/i, /\sduplex\s/i, /\sfaxcent(er|re)\s/i, \
    /\sworkcent(re|er)\s/i, /\smono\s/i, /\slaser\s/i, /\sdig(ital)?\s/i, /\scolou?r\s/i,\
    /\sb(lack\sand\s)?w(hite)?/i, /\snetwork\s/i, /\sall\s?-?\s?in\s?-?\s?one\s/i, /\sink\s/i,\
    /\schrome\s/i, /\stabloid\s/i, /\saio\sint\s/i, /\s\d+\s?x\s?\d+\s?(dpi)?\s/i, \
    /\sfast\s/i, /\sethernet\s/i, /\sled\s/i, /\d+\s?ppm/i]
end