class AjaxController < ApplicationController
  def preference
    mypreferences = params[:mypreference]
    $model::ContinuousFeatures.each do |f|
      @@session.features.update_attribute(f+"_pref", mypreferences[f+"_pref"])
    end
    # To stay on the current page 
    render :nothing => true
  end
   
  #Used for selecting a use case
  def select
    @@session.defaultFeatures(URI.encode(params[:id]))
    render :nothing => true
  end
  
  #Used for hiding some filters 
  def set_expert
    @@session.update_attribute('expert',params[:id])
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
        PreferenceRelation.createBinaryRelation(otherItems[otherItem], itemId, @@session.id, $Weight[source])
      else
        PreferenceRelation.createBinaryRelation(itemId, otherItems[otherItem], @@session.id, $Weight[source])
      end
    end    
    render :nothing => true
  end
end
