class CreateSessions < ActiveRecord::Migration
  def self.up
    #system "/usr/local/bin/rake db:properties"
    create_table :sessions do |t|
      t.timestamps
      t.primary_key :id
      t.string :user
      t.string :ip
      t.integer :parent_id
      t.string :product_type
      t.boolean :filter
      t.string :searchterm
      t.text :searchpids
    end
  end

  def self.down
    drop_table :sessions
  end
end
