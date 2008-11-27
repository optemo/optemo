class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|

      t.timestamps
      t.primary_key :id
      t.datetime :loaded_at
    end
  end

  def self.down
    drop_table :sessions
  end
end
