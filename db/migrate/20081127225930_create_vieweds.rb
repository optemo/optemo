class CreateVieweds < ActiveRecord::Migration
  def self.up
    create_table :vieweds do |t|

      t.timestamps
      t.integer :session_id, :camera_id
    end
  end

  def self.down
    drop_table :vieweds
  end
end
