class Dummy < ActiveRecord::Migration
  def self.up
    #remove_column :cameras, :productgroup
    #remove_column :reviews, :asin
    #add_column :printers, :bestoffer_ca, :integer
    #add_column :cameras, :bestoffer, :integer
    #add_column :cameras, :price_ca_str, :string
    #add_column :cameras, :instock_ca, :boolean
    add_column :scraped_cameras, :maximumresolution, :float
    remove_column :scraped_cameras, :resolutionmax
    #change_table :scraped_cameras do |t|
    #      t.timestamps
    #end
  end

  def self.down
    #remove_column :cameras, :noreviews
    #remove_column :scraped_cameras, :noreviews
  end
end
