class Dummy < ActiveRecord::Migration
  def self.up
    add_column :retailer_offerings, :local_id, :string
    add_column :retailers, :local_id_name, :string
  end

  def self.down
  end
end
