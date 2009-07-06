class PreferenceRelation < ActiveRecord::Base
  belongs_to :session
  
  # Create a row for binary relationship in PreferenceRelations table
   def self.createBinaryRelation(higher, lower, sessionId, weight)
     relation = {}
     relation [:higher] = higher
     relation[:lower] = lower
     relation[:session_id] = sessionId
     relation[:weight] = 0  # Keep weight 0 initially. Then if record is found or new record is created, add weight
     newRelation = PreferenceRelation.find_or_create_by_higher_and_lower_and_session_id(relation)
     newRelation.weight = newRelation.weight + weight
     newRelation.save
   end
   
   def self.deleteBinaryRelations
      # PreferenceRelation.delete_all() # Delete does not reset ID field, so use TRUNCATE
      ActiveRecord::Base.connection.execute('TRUNCATE preference_relations')
   end
   
end
