module Constants
  
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
    ['konica', 'konica-minolta', 'konica minolta'], ['okidata', 'oki data', 'oki'], ['kyocera', 'kyocera mita'] ]

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
  @@descriptors = [/mfp/i, /multifunct?ion/i, /duplex/i, /faxcent(er|re)/i, /workcent(re|er)/i, /mono/i,\
    /laser/i,/dig(ital)?/i, /color/,/b(lackand)?w(hite)?/ix, /network/i, /all-?in-?one/ix, /ink/i, /chrome/i,\
    /tabloid/i,/aio\sint/i, /\d+x\d+(dpi)?/ix, /fast/i, /ethernet/i, /led/i]
end