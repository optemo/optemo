class PreferenceRelation < ActiveRecord::Base
  belongs_to :session
  
  # Create a row for binary relationship in PreferenceRelations table
   def self.createBinaryRelation(higher, lower, sessionId, weight)
     relation = {}
     relation [:higher] = higher
     relation[:lower] = lower
     relation[:session_id] = sessionId
     relation[:weight] = weight
     newRelation = PreferenceRelation.new(relation)
     newRelation.save
   end
   
end
