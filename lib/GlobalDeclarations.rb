#$SITE_TITLE = 'LaserPrinterHub.com'
$DefaultProduct = 'printer_us'

# Configuration: Application Key provided by Facebook
$AppKey = "7aeec628ded26fb3b03829fb4142da01"

# Define Global variable for storing direction for each preference
$PrefDirection = Hash.new(1) # Set 1 i.e. Up as the default value for direction
$PrefDirection["price"] = -1 # -1 for down direction for preferences
$PrefDirection["itemwidth"] = -1
$PrefDirection["width"] = -1
$PrefDirection["miniorder"] = -1

$ProdTypeList = ['Printer','Camera','Flooring','Laptop']

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

# This parameter controls whether to go with the traditional box-layout or a line-item layout (from the hierarchy branch)
#$LineItemView = true

$Continuous = Hash.new{|h,k| h[k] = []}
$Binary = Hash.new{|h,k| h[k] = []}
$Categorical = Hash.new{|h,k| h[k] = []}
file = YAML::load(File.open("#{RAILS_ROOT}/config/products.yml"))
unless (file.nil? || file.empty?)
  file[$DefaultProduct].each do |feature,stuff| 
    type = stuff.first
    flags = stuff.second
    case type
    when "Continuous"
      flags.each{|flag| $Continuous[flag] << feature}
    when "Binary"
      flags.each{|flag| $Binary[flag] << feature}
    when "Categorical"
      flags.each{|flag| $Categorical[flag] << feature}
    end
  end
  $Continuous["all"] = []
  $Binary["all"] = []
  $Categorical["all"] = []
  file[$DefaultProduct].each{|feature,stuff| $Continuous["all"] << feature if stuff.first == "Continuous"}
  file[$DefaultProduct].each{|feature,stuff| $Binary["all"] << feature if stuff.first == "Binary"}
  file[$DefaultProduct].each{|feature,stuff| $Categorical["all"] << feature if stuff.first == "Categorical"}
end
