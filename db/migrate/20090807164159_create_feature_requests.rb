class CreateFeatureRequests < ActiveRecord::Migration
  def self.up
    create_table :feature_requests do |t|
      t.string :name
      t.string :email
      t.boolean :anonymous
      t.text :content
      t.integer :session_id

      t.timestamps
    end
  end

  def self.down
    drop_table :feature_requests
  end
end
