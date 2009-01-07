class AddChosenToSearch < ActiveRecord::Migration
  def self.up
    add_column :searches, :chosen, :text
  end

  def self.down
    remove_column :searches, :chosen
  end
end
