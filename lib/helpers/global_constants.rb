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
  $printer_brands = ["Advantus", "Apple", "ASUS", "Belkin", "Brother", "Buddy", "Canon", \
     "Copystar", "Curtis Manufacturing", "Dell", "Elite", "Epson", "Fargo", "General Ribbon Corporation", \
    "Genicom", "Global Marketing Partners", "Hewlett-Packard", "HP", "IBM", \
    'Kodak',"Konica-Minolta", "Kyocera", 'Lanier', "Lenovo", "Lexmark", "Media Science",\
    "Micro Innovations", 'NEC', "Oki Data", "Omni Mount", "Panasonic",\
    "Pitney Bowes", "Promedia", "QMS", "Ricoh", "Samsung", "Sharp", "Sunset", \
    "Tally", "Teac", "Thorens", "Toshiba", "Xerox"]
  
  $printer_series = ['imageclass','phaser','laserjet', 'laserwriter', 'oki', 'imagerunner', 'printer', 'printers', 'qms', \
    'estudio', 'optra', 'pro', 'officejet', 'workcentre', 'other', 'okifax', 'lanierfax', 'okipage',\
    'pixma', 'deskjet', 'stylus', 'docuprint', 'series','color', 'laser', 'printer','jet', 'business', 'clx']

  $brand_alternatives = [ ['hp', 'hewlett packard', 'hewlett-packard'], \
    ['konica', 'konica-minolta', 'konica minolta', 'minolta'], ['okidata', 'oki data', 'oki'],\
     ['kyocera', 'kyocera mita', 'finecam'], ['infoprint solutions', 'infoprint' ], ['argus', 'visiontek'],\
     ['concord', 'keystone', 'concord keystone'], ['fuji', 'fujifilm'], ['gopro', 'portable usa', 'gopro / portable usa'], \
     ['lg', 'lg electronics'], ['lomo', 'lomographic', 'lomography'], ['sea & sea', 'tabata usa'], \
     ['rollei', 'rolleiflex'], ['svp', 'silicon valley peripherals'], ['bell howell', 'bell + howell', \
       'bell & howell'], ['norcent', 'xias'], ['general electric', 'ge'], ['xerox', 'tektronix'], \
       ['intova', 'international innovations'], ['ibm', 'infoprint', 'infoprint solutions'], ['sealife', 'reef master'],\
       ['spectra', 'polaroid'], ['dxg', 'dxg usa', 'dxg technologies'], ['spectra', 'polaroid'], ['kodak', 'easyshare']]

  $cam_series = {'Agfa' => ['ePhoto'],'Canon' => ['EOS', 'PowerShot','Rebel', 'Power Shot', 'PShot'],'Casio' => ['Exilim','Photax'],
         'GoPro' => ['Digital Hero'], 'Fuji'=> ['Finepix'], 'Lomo' => ['Horizon'], 'Leica' => ['Digilux'],\
         'HP' => ['PhotoSmart'],'Kodak' => ['EasyShare'],'Mitsubishi' => ['ColorView'],\
         'Konica-Minolta' => ['DImage'],'Kyocera' => ['Finecam'],'Mustek' => ['GSmart', 'MDC'],\
         'Nikon' => ['Coolpix'],'Olympus' => ['Camedia', 'Stylus Tough', 'Stylus', 'PEN'],'Panasonic' => ['DMC',"Lumix"], \
         'Pentax' => ['Optio'],'Polaroid' => ['Photo', 'PhotoMAX', 'iZone'],\
         'Ricoh' => ['Caplio', 'GR'], 'Rollei' => ['Flexline'],'SVP' => ['Slim', 'Xthinn'],'Samsung' => ['Digimax'],\
         'SiPix' => ['StyleCam'],'Sony' => ['Cybershot', 'Mavica'],'Vivitar' => ['ViviCam'],'iSonic' => ['Snapbox'],\
         'Ezonics' => ['Opus'], 'Spectra' => ['Cool-iCam'],'Sanyo' => ['Xacti']}

  $conditions = ['Refurbished', 'Remanufactured', 'OEM', 'Used', 'New']

  $float_rxp = /(\d+,)?\d+(\.\d+)?/

  $units = ['MHz', 'ppm', 'MB', 'pixel', 'cm', 'mm', 'in', "\"", 'MP', 'Mpix',\
    'megapixel', 'Megapixel', 'MegaPixel', 'Mega Pixel', 'mp'] # TODO expand list
  
  $colors = [ 'black', 'green', 'blue', 'pink', 'red', 'beige', 'teal', 'purple', 'grey',\
     'gray', 'silver', 'white', 'champagne', 'pearl', 'titanium', 'crimson', 'espresso',\
     'yellow', 'azure']
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
  @@brands = ["Agfa", "Akai", "Argus", "Bell & Howell", "Benq", "Bushnell", "Canon", "Casio", "Cobra", \
  "Concord Keystone", "Contax", "Digital Concepts", 'Digital Blue', "DXG", "Electrolux", "Elyssa", \
  "Epson", 'Extech', 'Ezonics', 'FLIR', "Fuji", 'Digital Peripheral Solutions', 'Pelco',  \
  "CP Technologies",  'Lumens', 'Pelco', 'DeerCam', 'Photax', 'Diamond', 'Blue Thunder', 'Creative Labs', \
  "Gateway", "General Electric", "General Imaging", "GFM", "Go Photo", "GoPro / Portable USA", 'Hasbro', \
  "Hewlett Packard", "Insignia", "Intova", "iSonic", "Jazz", "JVC", "JWin", "Kobian ", "Kodak", \
  "Konica-Minolta", "Kyocera", 'Labtec', "Largan", "Leica", "LG Electronics", "Lomographic", "Memorex", \
  "Mercury", 'MGA Entertainment', "Mikona", "Minox", "Mitsubishi", "Mustek", "NEC", "Nikon", "Norcent", \
  "Olympus", "Oregon Scientific", "Panasonic", "Pentax", "Pixtreme", "Philips", "Polaroid", "Pretec", \
  "Radioshack", "Ricoh", "Rokinon", "Rollei", 'Sakar', "Samsung", "Sanyo", "Sea & Sea", "SeaLife", "Sharp",\
   "Sigma", "SiPix", "Sony", "Silicon Valley Peripherals", "Toshiba", "VistaQuest", "Vivitar", "VuPoint", \
   'Wildview',"Yashica"]
   # Lumens
   #

  @@series =  $cam_series.values.flatten
   #'Digital Blue' => ['Snap']
   #'SeaLife' => ['SL'], 
   # 'Gateway' => ['DC']
  @@descriptors = [/(\s|^)\d*\.?\d+\s?M(ega)?P(ix(el)?)?s?(\s|,|$)/i,/(\s|^)\d+\s?GB(\s|,|$|\/)/,  /(\s|^)body(,|\s|$)/i,\
    /LCD(\s|,|$)/i , /Two \(2\)/, /(\s|^)\d*\s?ISO\s?\d*(\s|,|$)/i, /\d(\s|-)in(\s|-)1/ , /(\s|^)kit(,|\s|$)/i,\
    /waterproof/i, /(\s|^)light(\s|,|$)/i, /(\s|^)SLR(\s|,|$)/, /(\s|^)\d*\.?\d+\s?x(\soptical|\sdigital)?(\szoom)?/i,\
    /(optical|digital)/i, /zoom/i, /(\s|^)digi?(\s|,|$)/i, /(\d\s?-?\s?)(month|day|year)(\swarranty)?/i,\
    /(\s|^)dark(\s|$)/i, /\d+(mm)?\s?-?\s?\d+(mm)/, /(-|^|\s)inch(\s|$|,)/, /wide(\sangle)/i, /tele/i, /dual/i , /(\s|^)image(\s|,|$)/i]
end

module PrinterConstants
  @@model = Printer
  @@scrapedmodel = ScrapedPrinter
  @@brands = $printer_brands
  @@series = $printer_series
  @@descriptors = [/\sMFP\s/, /\sdupl(ex)?(\s|,|$)/i, /\sfaxcent(er|re)\s/i, /\sink\s/i,\
   /(\s|\(|^)colou?r(\s|\)|4|\/)/i, /b(lack)?\s?(&(amp;)?|and)\s?w(hite)?/i, /\d+\s?MHz(\s|$|,)/i, \
   /\sall\s?-?\s?in\s?-?\s?one\s/i, /\saio\s(int\s)?\d+?/i, /(\s|^|,)le?ga?l(\s|,|$)/i, \
   /(\s|^|-|\/|,)\d*,?\d+\s?x\s?\d*,?\d+(dpi)?(\s|$|-|\/|,)/i, \
   /,?up to/i, /pcl\s?[56ec\/]*/i, \
   /(\s|^|,)\d*,?\d+(\.\d+)?\s?(to|--|\s-\s)\s?\d*,?\d+(\.\d+)?(\s|,|$|)/i, /(\s|^)to(\s|$)/,\
   /\d+\s?(M|G)B(\s|,|$)/, \
    /\d*,?\d+(\s|-)?(page|sheet)s?/i, /(\s|^|,)\d*(\s|-)?in(\s|-)?\d*(\s|$|,)/, /\d*,?\d*(\s|-)?dpi(\s|,|$)/i,\
    /\sfast\s/i, /\se(ther)?net\s/i, /\sled\s/i, /\sRS232\s/, /\d*((\/|-)?\d+)?\s?[pc]pm(\s|,|$|\/)/i, \
    /10\/100(B(ase)?-?TX?)?/i, /(\s|^|\/|\()(110|120|220|240)V(olt)?(\s|-|,|\/|$|\))/i, /\d+\s? fine\s?point/i,
    /\d+ image quality/i, /(\s|^|\/)A(3|4)(\s|,|$|\/)/,/(\s|^)USBPS3($|\s)/, /(\s|^|,)USB\s?(2(\.0?)|256)?(\s|,|$)/i,\
    /to \d+/, /pipe/, /(\s|^)par(\s|$)/i, /[01]*\/?[01]*base-tx?/i, /ieee1394/i, /series/i, \
    /(32|64|128|256|512)(\s|-)?(k|m)b/i, /(\s|^)CPU(\s|$|,)/, /(serial|parallel)/i, /shipping/i, /\d*(\s|-)?tray/i, \
    /\slaser\s/i, /black/i, /rolls?/i, /\d+(-|\s)?pin/i, /duplex/i, /\smono(chrome)?\s/i, /\d+\s?rpm/i, /sas \d+/i, \
    /letter/i,  /(\s|^|,)LCD(\s|,|$)/,  /(\s|^|,)drive(\s|,|$)/i, /(\s|^|,)type(\s|,|$)/i, /DDR[23]/,\
    /(\s|^|,)3G(\s|,|$)/, /console/, /as 1/, /\d+\s(sq\.\s?)?f(ee)?t(\s|,|$)/i, /(\s|^)2nd(\s|$)/i]
    # 10/100
    # 10/100Base-TX
    #  /\stabloid\s/i,
    #   /\sdig(ital)?\s/i,
   # /\smultifunct?ion\s/i, 
   # /legal/i, 
   # /printer/i, 
    # /\schrome\s/i,env: ruby: No such file or directory
    # /\snetwork\s/i,
   # /\sworkcent(re|er)\s/i, 
   #  , , 
    # /\d(\s|-)in(\s|-)1/i,
end