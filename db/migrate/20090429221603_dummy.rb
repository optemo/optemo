class Dummy < ActiveRecord::Migration
  def self.up
    #add_column :one23_cartridges, :real, :boolean#, :default => "New"
    #add_column :sessions, :user, :string
  end

  def self.down
    #remove_column :newegg_offerings, :url
    #remove_column :printers, :availability
  end
end
