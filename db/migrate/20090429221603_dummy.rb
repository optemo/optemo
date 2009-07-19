class Dummy < ActiveRecord::Migration
  def self.up

    #add_column :amazon_printers, :product_id, :integer
    #add_column :printers, :manufacturerproducturl, :string
    #add_column :printers, :averagereviewrating, :float
    #add_column :printers, :totalreviews, :integer
    #add_column :cameras, :averagereviewrating, :float
    #add_column :cameras, :totalreviews, :integer
    #add_column :amazon_printers, :averagereviewrating, :float
    #add_column :amazon_printers, :totalreviews, :integer
    #add_column :printer_nodes, :utility, :float
    #add_column :camera_nodes, :utility, :float
    add_column :printer_clusters, :utility, :float
    add_column :camera_clusters, :utility, :float
  end

  def self.down
    remove_column :newegg_offerings, :url
    #remove_column :printers, :availability
  end
end
