$DefaultSite = 'printers.browsethenbuy.com'

# Configuration: Application Key provided by Facebook
$AppKey = "7aeec628ded26fb3b03829fb4142da01"

# This is deprecated, but still referred to in upkeep.rake - clean this up some day
# $ProdTypeList = ['printer_us','flooring_builddirect']

# Define weights assigned to user navigation tasks that determine preferences
$Weight = Hash.new(0) # Set 0 as the default value for direction
$Weight["sim"] = 1
$Weight["saveit"] = 2
$Weight["unsave"] = 3
$Weight["unsaveComp"] = 4

# Parameter that decides how much difference in values (of a feature for different products) is considered significant
$margin = 10    # in %

# A threshold that decides whether a feature is important to the user or not. This is used when displaying important 
# qualities about compared products in the comparison matrix.
$SignificantFeatureThreshold = 0.2

#This parameter controls whether the interface features drag-and-drop comparison or not.
$DragAndDropEnabled = true
$RelativeDescriptions = true
$NumGroups = 9
$BoostexterLabels = true

# This parameter controls whether to go with the traditional box-layout or a line-item layout (from the hierarchy branch)
#$LineItemView = true

def load_defaults(url)
  $PrefDirection = Hash.new(1) # Set 1 i.e. Up as the default value for direction
  
  $Continuous = Hash.new{|h,k| h[k] = []}
  $Binary = Hash.new{|h,k| h[k] = []}
  $Categorical = Hash.new{|h,k| h[k] = []}
  file = YAML::load(File.open("#{RAILS_ROOT}/config/products.yml"))
  url = $DefaultSite if file[url].blank?
  product_yml = file[url]
  $product_type = product_yml["product_type"].first
  # This block gets out the continuous, binary, and categorical features
  product_yml.each do |feature,stuff| 
    type = stuff.first
    flags = stuff.second
    case type
    when "Continuous"
      flags.each{|flag| $Continuous[flag] << feature}
      options = stuff.third
      $PrefDirection[feature] = options["prefdir"] if options && options["prefdir"]
    when "Binary"
      flags.each{|flag| $Binary[flag] << feature}
    when "Categorical"
      flags.each{|flag| $Categorical[flag] << feature}
    end
    $Continuous["all"] = []
    $Binary["all"] = []
    $Categorical["all"] = []
    product_yml.each{|feature,stuff| $Continuous["all"] << feature if stuff.first == "Continuous"}
    product_yml.each{|feature,stuff| $Binary["all"] << feature if stuff.first == "Binary"}
    product_yml.each{|feature,stuff| $Categorical["all"] << feature if stuff.first == "Categorical"}

    # $LineItemView forces the use of the .lv CSS classes and renders the _listbox.html.erb partial instead of the _navbox.html.erb partial.
    # $SimpleLayout needs special clustering, or more precisely, no clustering, showing all products in browseable pages and offering "group by" buttons.
    $LineItemView = product_yml["layout"].first == "lineview" unless product_yml.nil? || product_yml["layout"].nil?
    $SimpleLayout = product_yml["layout"].second == "simple" unless product_yml.nil? || product_yml["layout"].nil?
    # At the moment, these are used in product scraping only.
    if feature == "price"
      $MaximumPrice = stuff.fourth.values.first
      $MinimumPrice = stuff.fifth.values.first
    end
  end
  
  $LineItemView ||= false #Default is grid view 
  $SimpleLayout ||= false #Default is normal clustering
end
