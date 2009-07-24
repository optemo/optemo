class AddIntl < ActiveRecord::Migration
  def self.up
    add_column :printer_features, :search_id, :integer
    add_column :camera_features, :search_id, :integer
    add_column :searches, :desc, :string
    add_column :retailer_offerings, :region, :string, :default => "us"
    add_column :printers, :price_ca, :integer
    add_column :printers, :price_ca_str, :string
    add_column :cameras, :price_ca, :integer
    add_column :cameras, :price_ca_str, :string
    add_column :printer_nodes, :region, :string, :default => "us"
    add_column :printer_clusters, :region, :string, :default => "us"
    add_column :camera_nodes, :region, :string, :default => "us"
    add_column :camera_clusters, :region, :string, :default => "us"
    add_column :sessions, :region, :string, :default => "us"
    add_column :db_features, :region, :string, :default => "us"
    add_column :retailers, :region, :string, :default => "us"
    add_column :amazon_printers, :region, :string, :default => "us"
    add_column :best_buy_products, :region, :string, :default => "us"
    add_column :newegg_printers, :region, :string, :default => "us"
    add_column :tiger_printers, :region, :string, :default => "us"
    add_column :printers, :instock_ca, :boolean
    add_column :cameras, :instock_ca, :boolean
  end

  def self.down
  end
end
