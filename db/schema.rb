# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090707195544) do

  create_table "amazon_groups", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "processed",          :default => false
    t.string   "url"
    t.string   "brand"
    t.string   "megapixels_range"
    t.string   "opticalZoom_range"
    t.string   "displaySize_range"
    t.string   "imageStabilization"
    t.string   "viewfinderType"
    t.boolean  "leaf",               :default => false
    t.datetime "scrapedAt"
  end

  create_table "amazon_printers", :force => true do |t|
    t.string   "asin"
    t.text     "detailpageurl"
    t.string   "binding"
    t.string   "brand"
    t.string   "color"
    t.string   "cpumanufacturer"
    t.float    "cpuspeed"
    t.string   "cputype"
    t.float    "displaysize"
    t.string   "ean"
    t.text     "feature"
    t.string   "graphicsmemorysize"
    t.boolean  "isautographed"
    t.boolean  "ismemorabilia"
    t.integer  "itemheight"
    t.integer  "itemlength"
    t.integer  "itemwidth"
    t.integer  "itemweight"
    t.string   "label"
    t.string   "language"
    t.string   "legaldisclaimer"
    t.string   "listpricestr"
    t.integer  "listpriceint"
    t.string   "manufacturer"
    t.string   "model"
    t.string   "modemdescription"
    t.string   "mpn"
    t.string   "nativeresolution"
    t.integer  "numberofitems"
    t.integer  "packageheight"
    t.integer  "packagelength"
    t.integer  "packagewidth"
    t.integer  "packageweight"
    t.integer  "processorcount"
    t.string   "productgroup"
    t.string   "publisher"
    t.text     "specialfeatures"
    t.string   "studio"
    t.integer  "systemmemorysize"
    t.string   "systemmemorytype"
    t.text     "title"
    t.string   "warranty"
    t.integer  "price"
    t.string   "pricestr"
    t.boolean  "iseligibleforsupersavershipping"
    t.string   "imagesurl"
    t.integer  "imagesheight"
    t.integer  "imageswidth"
    t.string   "imagemurl"
    t.integer  "imagemheight"
    t.integer  "imagemwidth"
    t.string   "imagelurl"
    t.integer  "imagelheight"
    t.integer  "imagelwidth"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "ppm"
    t.float    "ttp"
    t.string   "resolution"
    t.string   "duplex"
    t.string   "connectivity"
    t.string   "papersize"
    t.integer  "paperoutput"
    t.string   "dimensions"
    t.integer  "dutycycle"
    t.integer  "paperinput"
    t.string   "special"
    t.float    "ppmcolor"
    t.string   "platform"
    t.boolean  "colorprinter"
    t.boolean  "scanner"
    t.datetime "scrapedat"
    t.boolean  "nodetails"
    t.boolean  "printserver"
    t.boolean  "instock"
    t.string   "pricehistory"
    t.integer  "bestoffer"
    t.integer  "resolutionarea"
    t.integer  "resolutionmax"
    t.integer  "product_id"
  end

  create_table "best_buy_offerings", :force => true do |t|
    t.integer  "retailer_offering_id"
    t.string   "bb_class"
    t.integer  "classId"
    t.string   "subclass"
    t.integer  "subclassId"
    t.integer  "productId"
    t.string   "department"
    t.integer  "departmentId"
    t.string   "type"
    t.string   "categoryPath"
    t.string   "addToCartUrl"
    t.string   "affiliateUrl"
    t.string   "affiliateAddToCartUrl"
    t.string   "mobileUrl"
    t.string   "url"
    t.string   "cjAffiliateUrl"
    t.string   "cjAffiliateAddToCartUrl"
    t.string   "sku"
    t.string   "warrantyParts"
    t.string   "warrantyLabor"
    t.boolean  "bb_new"
    t.boolean  "nationalFeatured"
    t.boolean  "navigability"
    t.datetime "releaseDate"
    t.datetime "startDate"
    t.datetime "itemUpdateDate"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "best_buy_phones", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.string   "link"
    t.string   "category"
    t.string   "guid"
    t.string   "CategoryID"
    t.string   "Manufacturer"
    t.string   "ProvinceCode"
    t.string   "ImageUrl"
    t.string   "LongDescription"
    t.string   "CatGroup"
    t.string   "CatDept"
    t.string   "CatClass"
    t.string   "CatSubClass"
    t.string   "Price"
    t.string   "BacklitKeypad"
    t.string   "BatteryType"
    t.string   "CPUSpeed"
    t.string   "Calculator"
    t.string   "Calendar"
    t.string   "Carrier"
    t.string   "ChangeableFaceplateCapable"
    t.string   "ConnectionPort"
    t.string   "CustomizableRingTones"
    t.string   "DataCapabilities"
    t.string   "DisplayType"
    t.string   "ExpansionSlots"
    t.string   "Extras"
    t.string   "FlashUpgradeable"
    t.string   "Games"
    t.string   "HandsfreeSpeakerphone"
    t.string   "IncludedInBox"
    t.string   "KeyboardType"
    t.string   "KeypadLock"
    t.string   "MP3Capable"
    t.string   "MemorySize"
    t.string   "MfrPartNumber"
    t.string   "ModemType"
    t.string   "NumberofDisplayLines"
    t.string   "NumberofModes"
    t.string   "OperatingSystem"
    t.string   "OperatingSystemCompatibility"
    t.string   "OrderConditions"
    t.string   "PhoneBookCapacity"
    t.string   "ProductDimensions"
    t.string   "ProductWarranty"
    t.string   "ProductWeight"
    t.string   "ROMSize"
    t.string   "Resolution"
    t.string   "Spreadsheet"
    t.string   "StandbyTime"
    t.string   "StylusEntry"
    t.string   "SupportsCallerID"
    t.string   "TalkTime"
    t.string   "VibrateMode"
    t.string   "VoiceRecording"
    t.string   "WebBrowser"
    t.string   "WebCode"
    t.string   "WordProcessor"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "best_buy_printers", :force => true do |t|
    t.string   "bb_class"
    t.integer  "classId"
    t.string   "subclass"
    t.integer  "subclassId"
    t.integer  "productId"
    t.string   "department"
    t.integer  "departmentId"
    t.string   "type"
    t.string   "categoryPath"
    t.string   "addToCartUrl"
    t.string   "affiliateUrl"
    t.string   "affiliateAddToCartUrl"
    t.string   "mobileUrl"
    t.string   "url"
    t.string   "cjAffiliateUrl"
    t.string   "cjAffiliateAddToCartUrl"
    t.string   "sku"
    t.string   "warrantyParts"
    t.string   "warrantyLabor"
    t.boolean  "bb_new"
    t.boolean  "nationalFeatured"
    t.boolean  "navigability"
    t.datetime "releaseDate"
    t.datetime "startDate"
    t.datetime "itemUpdateDate"
    t.string   "source"
    t.boolean  "active"
    t.string   "activeUpdateDate"
    t.boolean  "printOnly"
    t.boolean  "inStoreAvailability"
    t.string   "inStoreAvailabilityText"
    t.datetime "inStoreAvailabilityUpdateDate"
    t.boolean  "onlineAvailability"
    t.string   "onlineAvailabilityText"
    t.datetime "onlineAvailabilityUpdateDate"
    t.float    "regularPrice"
    t.float    "salePrice"
    t.datetime "priceUpdateDate"
    t.string   "dollarSavings"
    t.float    "shippingCost"
    t.boolean  "freeShipping"
    t.string   "specialOrder"
    t.string   "orderable"
    t.string   "accessoriesImage"
    t.string   "angleImage"
    t.string   "remoteControlImage"
    t.string   "alternateViewsImage"
    t.string   "leftViewImage"
    t.string   "rightViewImage"
    t.string   "backViewImage"
    t.string   "topViewImage"
    t.string   "largeFrontImage"
    t.string   "thumbnailImage"
    t.string   "image"
    t.string   "mediumImage"
    t.string   "largeImage"
    t.string   "energyGuideImage"
    t.string   "name"
    t.string   "upc"
    t.string   "color"
    t.string   "modelNumber"
    t.string   "description"
    t.string   "shortDescription"
    t.text     "longDescription"
    t.string   "manufacturer"
    t.string   "weight"
    t.float    "width"
    t.float    "height"
    t.float    "depth"
    t.float    "shippingWeight"
    t.string   "format"
    t.integer  "customerReviewCount"
    t.float    "customerReviewAverage"
    t.integer  "printer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "best_buy_products", :force => true do |t|
    t.integer  "product_id"
    t.string   "product_type"
    t.string   "accessoriesImage"
    t.string   "angleImage"
    t.string   "remoteControlImage"
    t.string   "alternateViewsImage"
    t.string   "leftViewImage"
    t.string   "rightViewImage"
    t.string   "backViewImage"
    t.string   "topViewImage"
    t.string   "largeFrontImage"
    t.string   "thumbnailImage"
    t.string   "image"
    t.string   "mediumImage"
    t.string   "largeImage"
    t.string   "energyGuideImage"
    t.string   "name"
    t.string   "upc"
    t.string   "modelNumber"
    t.string   "description"
    t.string   "shortDescription"
    t.text     "longDescription"
    t.string   "manufacturer"
    t.string   "weight"
    t.float    "width"
    t.float    "height"
    t.float    "depth"
    t.float    "shippingWeight"
    t.integer  "customerReviewCount"
    t.float    "customerReviewAverage"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "camera_clusters", :force => true do |t|
    t.integer "parent_id"
    t.integer "layer"
    t.integer "cluster_size"
    t.string  "brand"
    t.float   "maximumresolution_min"
    t.float   "maximumresolution_max"
    t.float   "displaysize_min"
    t.float   "displaysize_max"
    t.float   "opticalzoom_min"
    t.float   "opticalzoom_max"
    t.float   "price_min"
    t.float   "price_max"
    t.integer "version"
  end

  create_table "camera_features", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "session_id"
    t.string   "brand",                  :default => "All Brands"
    t.float    "maximumresolution_min"
    t.float    "maximumresolution_max"
    t.float    "maximumresolution_pref", :default => 0.25
    t.float    "displaysize_min"
    t.float    "displaysize_max"
    t.float    "displaysize_pref",       :default => 0.25
    t.float    "opticalzoom_min"
    t.float    "opticalzoom_max"
    t.float    "opticalzoom_pref",       :default => 0.25
    t.float    "price_min"
    t.float    "price_max"
    t.float    "price_pref",             :default => 0.25
  end

  create_table "camera_nodes", :force => true do |t|
    t.integer "cluster_id"
    t.integer "product_id"
    t.float   "maximumresolution"
    t.float   "displaysize"
    t.float   "opticalzoom"
    t.float   "price"
    t.string  "brand"
    t.integer "version"
  end

  create_table "cameras", :force => true do |t|
    t.string   "asin"
    t.text     "detailpageurl"
    t.boolean  "batteriesincluded"
    t.string   "batterydescription"
    t.string   "binding"
    t.string   "brand"
    t.string   "connectivity"
    t.float    "digitalzoom"
    t.float    "displaysize"
    t.string   "ean"
    t.text     "feature"
    t.string   "floppydiskdrivedescription"
    t.boolean  "hasredeyereduction"
    t.string   "includedsoftware"
    t.boolean  "isautographed"
    t.boolean  "ismemorabilia"
    t.integer  "itemheight"
    t.integer  "itemlength"
    t.integer  "itemwidth"
    t.integer  "itemweight"
    t.string   "label"
    t.string   "listpricestr"
    t.integer  "listpriceint"
    t.string   "manufacturer"
    t.float    "maximumfocallength"
    t.float    "maximumresolution"
    t.float    "minimumfocallength"
    t.string   "model"
    t.string   "mpn"
    t.float    "opticalzoom"
    t.integer  "packageheight"
    t.integer  "packagelength"
    t.integer  "packagewidth"
    t.integer  "packageweight"
    t.string   "productgroup"
    t.string   "publisher"
    t.date     "releasedate"
    t.text     "specialfeatures"
    t.string   "studio"
    t.text     "title"
    t.string   "merchant"
    t.integer  "price"
    t.string   "pricestr"
    t.boolean  "iseligibleforsupersavershipping"
    t.string   "imagesurl"
    t.integer  "imagesheight"
    t.integer  "imageswidth"
    t.string   "imagemurl"
    t.integer  "imagemheight"
    t.integer  "imagemwidth"
    t.string   "imagelurl"
    t.integer  "imagelheight"
    t.integer  "imagelwidth"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "instock"
    t.string   "pricehistory"
    t.integer  "bestoffer"
  end

  create_table "db_features", :force => true do |t|
    t.string   "product_type"
    t.string   "feature_type"
    t.string   "name"
    t.float    "min"
    t.float    "max"
    t.float    "high"
    t.float    "low"
    t.text     "categories"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "db_properties", :force => true do |t|
    t.string   "name"
    t.text     "brands"
    t.float    "price_min"
    t.float    "price_max"
    t.float    "price_low"
    t.float    "price_high"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "factors", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "product_type"
    t.integer  "product_id"
    t.float    "maximumresolution"
    t.float    "displaysize"
    t.float    "opticalzoom"
    t.float    "price"
    t.float    "ppm"
    t.float    "itemwidth"
    t.float    "paperinput"
    t.float    "resolutionmax"
  end

  create_table "newegg_offerings", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "item_number"
    t.integer  "retailer_id"
    t.integer  "priceint"
    t.string   "pricestr"
    t.boolean  "toolow"
    t.datetime "priceUpdate"
    t.boolean  "stock"
    t.string   "availability"
    t.datetime "availabilityUpdate"
    t.string   "url"
    t.boolean  "active"
    t.datetime "activeUpdate"
    t.boolean  "freeShipping"
  end

  create_table "newegg_printer_scraped_datas", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "item_number"
    t.string   "manufacturer"
    t.string   "series"
    t.string   "brand"
    t.boolean  "toolow"
    t.float    "saleprice"
    t.float    "listprice"
    t.string   "imageurl"
    t.string   "model"
    t.string   "recommendeduse"
    t.string   "dimensions"
    t.integer  "weight"
    t.string   "outputtype"
    t.string   "lasertechnology"
    t.float    "blackprintspeed"
    t.float    "colorprintspeed"
    t.float    "timetofirstpageseconds"
    t.string   "blackprintquality"
    t.string   "colorprintquality"
    t.string   "printlanguagesstandard"
    t.string   "duplexprinting"
    t.integer  "maxdutycycle"
    t.string   "papertraysstd"
    t.string   "papertraysmax"
    t.integer  "inputcapacitystd"
    t.integer  "inputcapacitymax"
    t.integer  "outputcapacitystd"
    t.integer  "outputcapacitymax"
    t.string   "mediatype"
    t.string   "mediasizessupported"
    t.string   "usbports"
    t.string   "lptports"
    t.string   "networkports"
    t.string   "otherports"
    t.string   "microprocessortype"
    t.string   "microprocessormhz"
    t.string   "memorystd"
    t.string   "memorymax"
    t.string   "cartridgescompatible"
    t.string   "powerrequirements"
    t.string   "powerconsumption"
    t.string   "windowscompatible"
    t.string   "macintoshcompatible"
    t.string   "parts"
    t.string   "labor"
    t.string   "copyqualityblack"
    t.string   "scanresolutionenhanced"
    t.string   "windowsvista"
    t.string   "other"
    t.string   "faxfeatures"
    t.string   "noiselevelapprox"
    t.string   "modemspeed"
    t.string   "emulations"
    t.string   "comports"
    t.string   "display"
    t.string   "copyspeedblack"
    t.string   "maxdocumentenlargement"
    t.string   "maxdocumentreduction"
    t.string   "maxnumberofcopies"
    t.string   "scancolordepth"
    t.string   "scanresolutionoptical"
    t.string   "packagecontents"
    t.string   "faxmemory"
    t.string   "copyspeedcolor"
    t.string   "faxtransmissionspeed"
    t.string   "scanelement"
    t.string   "faxresolutions"
    t.string   "softwareincluded"
    t.string   "connectivitytechnology"
    t.string   "colorfax"
    t.string   "copyqualitycolor"
    t.string   "borderlessphotosizes"
    t.string   "scanresolutionhardware"
  end

  create_table "newegg_printers", :force => true do |t|
    t.string   "item_number"
    t.string   "model"
    t.string   "series"
    t.string   "brand"
    t.integer  "listpriceint"
    t.string   "listpricestr"
    t.string   "imageurl"
    t.text     "detailpageurl"
    t.string   "recommendeduse"
    t.string   "dimensions"
    t.integer  "itemheight"
    t.integer  "itemwidth"
    t.integer  "itemlength"
    t.integer  "itemweight"
    t.boolean  "colorprinter"
    t.boolean  "printserver"
    t.boolean  "scanner"
    t.datetime "scrapedat"
    t.string   "lasertechnology"
    t.string   "platform"
    t.string   "warranty"
    t.float    "ppm"
    t.float    "ppmcolor"
    t.float    "ttp"
    t.string   "resolution"
    t.string   "language"
    t.string   "duplex"
    t.integer  "dutycycle"
    t.integer  "paperinput"
    t.integer  "paperinputmax"
    t.integer  "paperoutput"
    t.integer  "paperoutputmax"
    t.string   "systemmemory"
    t.string   "systemmemorymax"
    t.string   "mediatype"
    t.string   "papersize"
    t.string   "cputype"
    t.float    "cpuspeed"
    t.string   "connectivity"
    t.string   "special"
    t.string   "usbports"
    t.string   "lptports"
    t.string   "networkports"
    t.string   "otherports"
    t.string   "comports"
    t.string   "copyspeedblack"
    t.string   "copyspeedcolor"
    t.string   "copyqualityblack"
    t.string   "copyqualitycolor"
    t.string   "maxnumberofcopies"
    t.string   "scanresolutionenhanced"
    t.string   "maxdocumentenlargement"
    t.string   "maxdocumentreduction"
    t.string   "scancolordepth"
    t.string   "scanresolutionoptical"
    t.string   "scanresolutionhardware"
    t.string   "scanelement"
    t.string   "faxfeatures"
    t.string   "faxmemory"
    t.string   "faxtransmissionspeed"
    t.string   "colorfax"
    t.string   "faxresolutions"
    t.string   "noiselevelapprox"
    t.string   "modemspeed"
    t.string   "emulations"
    t.string   "display"
    t.string   "packagecontents"
    t.string   "softwareincluded"
    t.string   "borderlessphotosizes"
    t.string   "colorresolution"
    t.string   "papertraysstd"
    t.string   "papertraysmax"
    t.string   "cartridgescompatible"
    t.string   "powerrequirements"
    t.string   "powerconsumption"
  end

  create_table "optemo_development", :force => true do |t|
    t.string "label", :limit => 1
  end

  create_table "printer_clusters", :force => true do |t|
    t.integer "parent_id"
    t.integer "layer"
    t.integer "cluster_size"
    t.float   "ppm_min"
    t.float   "ppm_max"
    t.float   "itemwidth_min"
    t.float   "itemwidth_max"
    t.float   "paperinput_min"
    t.float   "paperinput_max"
    t.integer "resolutionmax_min"
    t.integer "resolutionmax_max"
    t.float   "price_max"
    t.float   "price_min"
    t.string  "brand"
    t.boolean "scanner"
    t.boolean "printserver"
    t.integer "version"
  end

  create_table "printer_features", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "session_id"
    t.float    "ppm_min"
    t.float    "ppm_max"
    t.float    "ppm_pref",           :default => 0.2
    t.float    "itemwidth_min"
    t.float    "itemwidth_max"
    t.float    "itemwidth_pref",     :default => 0.2
    t.float    "paperinput_min"
    t.float    "paperinput_max"
    t.float    "paperinput_pref",    :default => 0.2
    t.float    "resolutionmax_min"
    t.float    "resolutionmax_max"
    t.float    "resolutionmax_pref", :default => 0.2
    t.float    "price_min"
    t.float    "price_max"
    t.float    "price_pref",         :default => 0.2
    t.string   "brand",              :default => "All Brands"
    t.boolean  "scanner"
    t.boolean  "printserver"
  end

  create_table "printer_nodes", :force => true do |t|
    t.integer "cluster_id"
    t.integer "product_id"
    t.float   "ppm"
    t.float   "itemwidth"
    t.float   "paperinput"
    t.integer "resolutionmax"
    t.boolean "scanner"
    t.boolean "printserver"
    t.float   "price"
    t.string  "brand"
    t.integer "version"
  end

  create_table "printers", :force => true do |t|
    t.string   "brand"
    t.float    "displaysize"
    t.string   "ean"
    t.text     "feature"
    t.integer  "itemheight"
    t.integer  "itemlength"
    t.integer  "itemwidth"
    t.integer  "itemweight"
    t.integer  "listpriceint"
    t.string   "model"
    t.string   "mpn"
    t.integer  "packageheight"
    t.integer  "packagelength"
    t.integer  "packagewidth"
    t.integer  "packageweight"
    t.text     "title"
    t.string   "warranty"
    t.integer  "price"
    t.string   "pricestr"
    t.boolean  "iseligibleforsupersavershipping"
    t.string   "imagesurl"
    t.integer  "imagesheight"
    t.integer  "imageswidth"
    t.string   "imagemurl"
    t.integer  "imagemheight"
    t.integer  "imagemwidth"
    t.string   "imagelurl"
    t.integer  "imagelheight"
    t.integer  "imagelwidth"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "ppm"
    t.float    "ttp"
    t.string   "resolution"
    t.string   "duplex"
    t.string   "connectivity"
    t.string   "papersize"
    t.integer  "paperoutput"
    t.string   "dimensions"
    t.integer  "dutycycle"
    t.integer  "paperinput"
    t.string   "special"
    t.float    "ppmcolor"
    t.string   "platform"
    t.boolean  "colorprinter"
    t.boolean  "scanner"
    t.datetime "scrapedat"
    t.boolean  "nodetails"
    t.boolean  "printserver"
    t.boolean  "instock"
    t.string   "pricehistory"
    t.integer  "bestoffer"
    t.integer  "resolutionarea"
    t.integer  "resolutionmax"
    t.string   "manufacturerproducturl"
  end

  create_table "referrals", :force => true do |t|
    t.integer  "product_id"
    t.string   "product_type"
    t.integer  "session_id"
    t.integer  "retailer_offering_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "retailer_offerings", :force => true do |t|
    t.integer  "product_id"
    t.string   "product_type"
    t.integer  "priceint"
    t.string   "pricestr"
    t.integer  "tax"
    t.string   "state"
    t.integer  "retailer_id"
    t.boolean  "stock"
    t.string   "pricehistory"
    t.boolean  "toolow"
    t.string   "availability"
    t.boolean  "iseligibleforsupersavershipping"
    t.string   "merchant"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "shippingCost"
    t.boolean  "freeShipping"
    t.datetime "priceUpdate"
    t.datetime "availabilityUpdate"
    t.boolean  "active"
    t.datetime "activeUpdate"
  end

  create_table "retailers", :force => true do |t|
    t.string   "url"
    t.string   "name"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "saveds", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "session_id"
    t.integer  "product_id"
    t.integer  "search_id"
  end

  create_table "searches", :force => true do |t|
    t.integer  "session_id"
    t.integer  "parent_id"
    t.integer  "layer"
    t.string   "c0"
    t.string   "c1"
    t.string   "c2"
    t.string   "c3"
    t.string   "c4"
    t.string   "c5"
    t.string   "c6"
    t.string   "c7"
    t.string   "c8"
    t.integer  "cluster_count"
    t.integer  "result_count"
    t.string   "brand",         :default => "All Brands"
    t.float    "price_min",     :default => 0.0
    t.float    "price_max",     :default => 10000000.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip"
    t.integer  "parent_id"
    t.string   "product_type"
    t.boolean  "filter"
    t.string   "searchterm"
    t.text     "searchpids"
  end

  create_table "vieweds", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "session_id"
    t.integer  "product_id"
    t.integer  "search_id"
  end

  create_table "welcomes", :force => true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
