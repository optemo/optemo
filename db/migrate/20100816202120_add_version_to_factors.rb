class AddVersionToFactors < ActiveRecord::Migration
  def self.up
    add_column :factors, :version, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :factors, :version
  end
end
