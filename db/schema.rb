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

ActiveRecord::Schema.define(:version => 20090901210645) do

  create_table "amazon_alls", :force => true do |t|
    t.text     "title"
    t.integer  "price"
    t.string   "pricestr"
    t.boolean  "iseligibleforsupersavershipping"
    t.integer  "bestoffer"
    t.string   "pricehistory"
    t.string   "imagesurl"
    t.integer  "imagesheight"
    t.integer  "imageswidth"
    t.string   "imagemurl"
    t.integer  "imagemheight"
    t.integer  "imagemwidth"
    t.string   "imagelurl"
    t.integer  "imagelheight"
    t.integer  "imagelwidth"
    t.boolean  "instock"
    t.float    "averagereviewrating"
    t.integer  "totalreviews"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "warranty"
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
    t.integer  "resolutionmax"
    t.boolean  "fax"
    t.boolean  "bw"
    t.integer  "resolutionarea"
    t.integer  "product_id"
    t.string   "product_type",                    :default => "Printer"
  end

  create_table "amazon_cartridges", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "brand"
    t.string   "model"
    t.string   "mpn"
    t.string   "asin"
    t.integer  "product_id"
    t.text     "detailpageurl"
    t.string   "yieldstr"
    t.integer  "yield"
    t.string   "shelflifestr"
    t.integer  "shelflife"
    t.string   "color"
    t.string   "brandnameprice"
    t.integer  "brandnamepriceint"
    t.text     "compatible"
    t.string   "listprice"
    t.integer  "listpriceint"
    t.text     "imageurl"
    t.text     "title"
    t.integer  "price"
    t.string   "pricestr"
    t.boolean  "iseligibleforsupersavershipping"
    t.integer  "bestoffer"
    t.string   "pricehistory"
    t.string   "imagesurl"
    t.integer  "imagesheight"
    t.integer  "imageswidth"
    t.string   "imagemurl"
    t.integer  "imagemheight"
    t.integer  "imagemwidth"
    t.string   "imagelurl"
    t.integer  "imagelheight"
    t.integer  "imagelwidth"
    t.boolean  "instock"
    t.float    "averagereviewrating"
    t.integer  "totalreviews"
    t.string   "dimensions"
    t.integer  "itemwidth"
    t.integer  "itemlength"
    t.integer  "itemheight"
    t.integer  "packageheight"
    t.integer  "packagelength"
    t.integer  "packagewidth"
    t.integer  "packageweight"
    t.string   "warranty"
    t.text     "manufacturerproducturl"
    t.string   "product_type"
    t.integer  "retailer_id"
    t.string   "region"
    t.string   "merchant"
    t.string   "saleprice"
    t.string   "yousave"
    t.datetime "priceUpdate"
    t.integer  "shippingCost"
    t.integer  "tax"
    t.string   "state"
    t.boolean  "stock"
    t.boolean  "toolow"
    t.string   "availability"
    t.datetime "availabilityUpdate"
    t.text     "url"
    t.boolean  "active"
    t.datetime "activeUpdate"
    t.boolean  "freeShipping"
    t.boolean  "real"
    t.boolean  "toner"
    t.string   "condition"
    t.string   "realbrand"
    t.string   "compatiblebrand"
    t.integer  "offering_id"
    t.datetime "scrapedat"
    t.integer  "numberofitems"
    t.text     "specialfeatures"
  end

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
    t.text     "title"
    t.integer  "price"
    t.string   "pricestr"
    t.boolean  "iseligibleforsupersavershipping"
    t.integer  "bestoffer"
    t.string   "pricehistory"
    t.string   "imagesurl"
    t.integer  "imagesheight"
    t.integer  "imageswidth"
    t.string   "imagemurl"
    t.integer  "imagemheight"
    t.integer  "imagemwidth"
    t.string   "imagelurl"
    t.integer  "imagelheight"
    t.integer  "imagelwidth"
    t.boolean  "instock"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "warranty"
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
    t.integer  "resolutionmax"
    t.boolean  "fax"
    t.boolean  "bw"
    t.integer  "resolutionarea"
    t.integer  "product_id"
    t.string   "product_type",                    :default => "Printer"
    t.float    "averagereviewrating"
    t.integer  "totalreviews"
    t.string   "region",                          :default => "us"
  end

  create_table "best_buy_cameras", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "skuid"
    t.text     "label"
    t.text     "detailpageurl"
    t.text     "imageurl"
    t.text     "glossary"
    t.string   "viewfindertype"
    t.boolean  "waterproof"
    t.boolean  "slr"
    t.string   "mpn"
    t.string   "brand"
    t.string   "model"
    t.float    "displaysize"
    t.string   "listpricestr"
    t.integer  "listpriceint"
    t.float    "opticalzoom"
    t.float    "digitalzoom"
    t.float    "maximumresolution"
    t.string   "batterydescription"
    t.boolean  "hasredeyereduction"
    t.float    "itemheight"
    t.float    "itemlength"
    t.float    "itemwidth"
    t.float    "itemweight"
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

  create_table "best_buy_pilot_offerings", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category"
    t.string   "categoryid"
    t.string   "catgroup"
    t.string   "catsubclass"
    t.string   "fsskuid"
    t.string   "skuid"
    t.string   "guid"
    t.string   "webcode"
    t.integer  "bb_camera_id"
    t.text     "link"
    t.text     "imageurl"
    t.text     "glossary"
    t.string   "saleenddate"
    t.string   "saleprice"
    t.string   "savings"
    t.string   "pricestr"
    t.integer  "priceint"
    t.integer  "product_id"
    t.string   "product_type"
    t.integer  "retailer_id"
    t.string   "pricehistory"
    t.string   "region"
    t.datetime "priceUpdate"
    t.integer  "shippingCost"
    t.integer  "tax"
    t.string   "state"
    t.boolean  "stock"
    t.boolean  "toolow"
    t.string   "availability"
    t.datetime "availabilityUpdate"
    t.text     "url"
    t.boolean  "active"
    t.datetime "activeUpdate"
    t.boolean  "freeShipping"
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
    t.string   "region",                :default => "us"
  end

  create_table "bestbuy_scrapeds", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category"
    t.string   "categoryid"
    t.string   "catgroup"
    t.string   "catsubclass"
    t.string   "fsskuid"
    t.string   "skuid"
    t.string   "guid"
    t.text     "label"
    t.text     "detailpageurl"
    t.text     "imageurl"
    t.text     "glossary"
    t.text     "description"
    t.string   "includedbatterymodel"
    t.text     "longdescription"
    t.string   "redeyereductionflashmode"
    t.string   "redeyeremoval"
    t.string   "resolutionhighestqualitymode"
    t.string   "resolutionlowestqualitymode"
    t.string   "resolutionmediumqualitymode"
    t.string   "saleenddate"
    t.string   "saleprice"
    t.string   "savings"
    t.string   "viewfindertype"
    t.string   "webcode"
    t.string   "mpn"
    t.string   "brand"
    t.string   "model"
    t.float    "displaysize"
    t.string   "listpricestr"
    t.integer  "listpriceint"
    t.float    "opticalzoom"
    t.float    "digitalzoom"
    t.float    "maximumresolution"
    t.float    "itemheight"
    t.float    "itemlength"
    t.float    "itemwidth"
    t.float    "itemweight"
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
    t.integer "version",               :default => 0
    t.float   "cached_utility"
    t.string  "region",                :default => "us"
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
    t.integer  "search_id"
  end

  create_table "camera_nodes", :force => true do |t|
    t.integer "cluster_id"
    t.integer "product_id"
    t.float   "maximumresolution"
    t.float   "displaysize"
    t.float   "opticalzoom"
    t.float   "price"
    t.string  "brand"
    t.integer "version",           :default => 0
    t.float   "utility"
    t.string  "region",            :default => "us"
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
    t.float    "averagereviewrating"
    t.integer  "totalreviews"
    t.integer  "price_ca"
    t.string   "price_ca_str"
    t.boolean  "instock_ca"
  end

