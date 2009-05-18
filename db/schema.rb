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

ActiveRecord::Schema.define(:version => 20090429221603) do

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

  create_table "camera_clusters", :force => true do |t|
    t.integer "parent_id"
    t.integer "layer"
    t.integer "cluster_size"
    t.float   "maximumresolution_max"
    t.float   "maximumresolution_min"
    t.float   "displaysize_max"
    t.float   "displaysize_min"
    t.float   "opticalzoom_max"
    t.float   "opticalzoom_min"
    t.float   "price_max"
    t.float   "price_min"
  end

  create_table "camera_nodes", :force => true do |t|
    t.integer "cluster_id"
    t.integer "product_id"
    t.float   "maximumresolution"
    t.float   "displaysize"
    t.float   "opticalzoom"
    t.float   "price"
    t.string  "brand"
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
    t.integer  "salepriceint"
    t.string   "salepricestr"
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
    t.integer  "db_property_id"
    t.string   "name"
    t.float    "min"
    t.float    "max"
    t.float    "high"
    t.float    "low"
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

  create_table "newegg_printers", :force => true do |t|
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
    t.integer  "upc"
    t.string   "warranty"
    t.string   "merchantid"
    t.string   "merchantname"
    t.integer  "salepriceint"
    t.string   "salepricestr"
    t.string   "availability"
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
    t.boolean  "toolow"
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
    t.string   "oldprices"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.float   "price_max"
    t.float   "price_min"
  end

  create_table "printer_nodes", :force => true do |t|
    t.integer "cluster_id"
    t.integer "product_id"
    t.float   "ppm"
    t.float   "itemwidth"
    t.float   "paperinput"
    t.float   "price"
    t.string  "brand"
  end

  create_table "printers", :force => true do |t|
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
    t.integer  "salepriceint"
    t.string   "salepricestr"
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
    t.integer  "shipping"
    t.integer  "tax"
    t.string   "state"
    t.string   "link"
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
    t.integer  "cluster_id"
    t.integer  "product_id"
    t.integer  "filter"
    t.string   "brand",                 :default => "All Brands"
    t.float    "maximumresolution_min", :default => 0.0
    t.float    "maximumresolution_max", :default => 15.0
    t.float    "displaysize_min",       :default => 0.0
    t.float    "displaysize_max",       :default => 4.0
    t.float    "opticalzoom_min",       :default => 0.0
    t.float    "opticalzoom_max",       :default => 20.0
    t.float    "ppm_min",               :default => 5.0
    t.float    "ppm_max",               :default => 60.0
    t.float    "itemwidth_min",         :default => 0.0
    t.float    "itemwidth_max",         :default => 6290.0
    t.float    "paperinput_min",        :default => 50.0
    t.float    "paperinput_max",        :default => 4100.0
    t.float    "price_min",             :default => 0.0
    t.float    "price_max",             :default => 10000000.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "maximumresolution_min",  :default => 0.0
    t.float    "maximumresolution_max",  :default => 15.0
    t.string   "maximumresolution_hist"
    t.float    "displaysize_min",        :default => 0.0
    t.float    "displaysize_max",        :default => 4.0
    t.string   "displaysize_hist"
    t.float    "opticalzoom_min",        :default => 0.0
    t.float    "opticalzoom_max",        :default => 20.0
    t.string   "opticalzoom_hist"
    t.float    "ppm_min",                :default => 5.0
    t.float    "ppm_max",                :default => 60.0
    t.string   "ppm_hist"
    t.float    "itemwidth_min",          :default => 0.0
    t.float    "itemwidth_max",          :default => 6290.0
    t.string   "itemwidth_hist"
    t.float    "paperinput_min",         :default => 50.0
    t.float    "paperinput_max",         :default => 4100.0
    t.string   "paperinput_hist"
    t.float    "price_min",              :default => 0.0
    t.float    "price_max",              :default => 10000000.0
    t.string   "price_hist"
    t.integer  "result_count"
    t.integer  "i0"
    t.integer  "i1"
    t.integer  "i2"
    t.integer  "i3"
    t.integer  "i4"
    t.integer  "i5"
    t.integer  "i6"
    t.integer  "i7"
    t.integer  "i8"
    t.integer  "c0"
    t.integer  "c1"
    t.integer  "c2"
    t.integer  "c3"
    t.integer  "c4"
    t.integer  "c5"
    t.integer  "c6"
    t.integer  "c7"
    t.integer  "c8"
    t.text     "chosen"
    t.string   "msg"
  end

  create_table "test", :id => false, :force => true do |t|
    t.binary "blob_col"
  end

  add_index "test", ["blob_col"], :name => "blob_col"

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
