class CreatePreferenceRelations < ActiveRecord::Migration
  def self.up
    create_table :preference_relations do |t|

      t.timestamps
      t.primary_key :id
      t.integer :session_id
      t.integer :lower
      t.integer :higher
      t.float :weight      
    end
  end

  def self.down
    drop_table :preference_relations
  end
end
