
$SITE_TITLE = 'LaserPrinterHub.com'

# Define Global variable for storing direction for each preference
$PrefDirection = Hash.new(1) # Set 1 i.e. Up as the default value for direction
$PrefDirection["price"] = -1 # -1 for down direction for preferences
$PrefDirection["itemwidth"] = -1

$ProdTypeList = ['Printer','Camera']

# Define weights assigned to user navigation tasks that determine preferences
$Weight["representative"] = 10
$Weight["saveit"] = 20
