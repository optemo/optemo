class CreateRetailers < ActiveRecord::Migration
  def self.up
    create_table :retailers do |t|
      t.string :url
      t.string :name
      t.string :image

      t.string  :local_id_name

      t.timestamps
    end
  end

  def self.down
    drop_table :retailers
  end
end
