class AjaxController < ApplicationController
  # In the past, this was in GlobalDeclarations.rb, but I think that it related to the weight calculations
  # that go on in this controller, maybe? Kept here purely for archeological reasons. ZAT August 2010
  
  # Parameter that decides how much difference in values (of a feature for different products) is considered significant
  # $margin = 10    # in %
  # A threshold that decides whether a feature is important to the user or not. This is used when displaying important 
  # qualities about compared products in the comparison matrix.
  # $SignificantFeatureThreshold = 0.2
  
  def preference
    mypreferences = params[:mypreference]
    s = Session
    s.continuous["filter"].each do |f|
      s.features.update_attribute(f+"_pref", mypreferences[f+"_pref"])
    end
    # To stay on the current page 
    render :nothing => true
  end
    
  def buildrelations
    # Define weights assigned to user navigation tasks that determine preferences
    weight = Hash.new("sim" => 1, "saveit" => 2, "unsave" => 3, "unsaveComp" => 4) 

    source = params[:source]
    itemId = params[:itemId]
    # Convert the parameter string into an array of integers
    otherItems = params[:otherItems].split(",").collect{ |s| s.to_i }
    for otherItem in 0..otherItems.count-1
      # If the source is unsave i.e. a saved product has been dropped, then
      # create relations with lower as the dropped item and higher as all other saved items 
      if source == "unsave" || source == "unsaveComp"
        PreferenceRelation.createBinaryRelation(otherItems[otherItem], itemId, Session.id, weight[source])
      else
        PreferenceRelation.createBinaryRelation(itemId, otherItems[otherItem], Session.id, weight[source])
      end
    end    
    render :nothing => true
  end
end
