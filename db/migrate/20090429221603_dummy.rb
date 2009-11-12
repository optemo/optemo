class Dummy < ActiveRecord::Migration
  def self.up
    #remove_column :cameras, :productgroup
    #remove_column :cameras, :asin
    #add_column :scraped_cameras, :aa_batteries, :boolean
    #add_column :cameras, :reviewtext, :text
    #add_column :cameras, :resolution, :string
    #add_column :cameras, :resolutionmax, :float
    #add_column :scraped_cameras, :bodyonly, :boolean
    #remove_column :cameras, :binding
    #change_table :scraped_cameras do |t|
    #      t.timestamps
    #end
  end

  def self.down
    #remove_column :cameras, :binding
  end
end
