
$SITE_TITLE = 'LaserPrinterHub.com'

# Define Global variable for storing direction for each preference
$PrefDirection = Hash.new(1) # Set 1 i.e. Up as the default value for direction
$PrefDirection["price"] = -1 # -1 for down direction for preferences
$PrefDirection["itemwidth"] = -1

$ProdTypeList = ['Printer','Camera']

# Define weights assigned to user navigation tasks that determine preferences
$Weight = Hash.new(0) # Set 0 as the default value for direction
$Weight["sim"] = 1
$Weight["saveit"] = 2

#These are the default use cases which should match the uses.yml file
$DefaultUses = Hash[*%w(corporate small_office home_office photography).sort.reverse.zip((1..4).to_a).flatten]
