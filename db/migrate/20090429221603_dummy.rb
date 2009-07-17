class Dummy < ActiveRecord::Migration
  def self.up
    add_column :newegg_offerings, :url, :text
  end

  def self.down
    remove_column :newegg_offerings, :url
    #remove_column :printers, :availability
  end
end
