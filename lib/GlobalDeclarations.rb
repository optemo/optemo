$SITE_TITLE = 'LaserPrinterHub.com'
$DefaultProduct = 'Printer'

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

#These are the default use cases which should match the uses.yml file
$DefaultUses = Hash[*%w(corporate small_office home_office photography).sort.reverse.zip((1..4).to_a.map{|i|i*2}).flatten]

#This parameter controls whether the interface features drag-and-drop comparison or not.
$DragAndDropEnabled = true
$RelativeDescriptions = true
$NumGroups = 9

# This parameter controls whether to go with the traditional box-layout or a line-item layout (from the hierarchy branch)
#$LineItemView = true
