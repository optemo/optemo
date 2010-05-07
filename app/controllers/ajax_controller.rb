class AjaxController < ApplicationController
  def preference
    mypreferences = params[:mypreference]
    $Continuous["filter"].each do |f|
      Session.current.features.update_attribute(f+"_pref", mypreferences[f+"_pref"])
    end
    # To stay on the current page 
    render :nothing => true
  end
    
  def buildrelations
    source = params[:source]
    itemId = params[:itemId]
    # Convert the parameter string into an array of integers
    otherItems = params[:otherItems].split(",").collect{ |s| s.to_i }
    for otherItem in 0..otherItems.count-1
      # If the source is unsave i.e. a saved product has been dropped, then
      # create relations with lower as the dropped item and higher as all other saved items 
      if source == "unsave" || source == "unsaveComp"
        PreferenceRelation.createBinaryRelation(otherItems[otherItem], itemId, Session.current.id, $Weight[source])
      else
        PreferenceRelation.createBinaryRelation(itemId, otherItems[otherItem], Session.current.id, $Weight[source])
      end
    end    
    render :nothing => true
  end
end
