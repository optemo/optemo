module Constants
  
  $printer_brands = ["3com", "Advantus", "Apple", "ASUS", "Belkin", "Brother", "Buddy", "Canon", \
     "Copystar", "Curtis Manufacturing", "Dell", "Elite", "Epson", "Fargo", "General Ribbon Corporation", \
    "Genicom", "Global Marketing Partners", "Hewlett-Packard", "HP", "IBM", "Infoprint Solutions",\
    'Kodak',"Konica", "Konica-Minolta", "Kyocera", 'Lanier', "Lenovo", "Lexmark", "Media science",\
    "Micro Innovations", "Minolta", "Oki Data", "Omni Mount", "Panasonic",\
    "Pitney Bowes", "Promedia", "QMS", "Ricoh", "Samsung", "Sharp", "Sunset", \
    "Tally", "Teac", "Tektronix", "Thorens", "Toshiba", "Xerox"]
  
  $printer_series = ['imageclass','phaser','laserjet', 'laserwriter', 'oki', 'imagerunner', 'printer', 'printers', 'qms', \
    'estudio', 'optra', 'pro', 'officejet', 'workcentre', 'other', 'okifax', 'lanierfax', 'okipage',\
    'pixma', 'deskjet', 'stylus', 'docuprint', 'series','color', 'laser', 'printer','jet', 'business']

  $brand_alternatives = [ ['hp', 'hewlett packard', 'hewlett-packard'], \
    ['konica', 'konica-minolta', 'konica minolta'], ['okidata', 'oki data', 'oki'], ['kyocera', 'kyocera mita'] ]

  $conditions = ['Refurbished', 'Remanufactured', 'OEM', 'Used', 'New']

  $float_rxp = /(\d+,)?\d+(\.\d+)?/

end