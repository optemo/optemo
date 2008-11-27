class CreateSimilars < ActiveRecord::Migration
  def self.up
    create_table :similars do |t|

      t.timestamps
      t.integer :session_id, :camera_id
    end
  end

  def self.down
    drop_table :similars
  end
end
