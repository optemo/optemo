class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences do |t|

      t.timestamps
      
      t.primary_key :id
      t.string :prefname
      t.float :prefval
      t.integer :sessionid
      t.integer :searchid
      t.string :producttype
      
    end
  end

  def self.down
    drop_table :preferences
  end
end
