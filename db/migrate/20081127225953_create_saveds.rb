class CreateSaveds < ActiveRecord::Migration
  def self.up
    create_table :saveds do |t|

      t.timestamps
      t.integer :session_id, :camera_id, :search_id
    end
  end

  def self.down
    drop_table :saveds
  end
end
