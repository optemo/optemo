class AddExpert < ActiveRecord::Migration
  def self.up
    add_column :sessions, :expert, :boolean, :default => false
  end

  def self.down
  end
end
