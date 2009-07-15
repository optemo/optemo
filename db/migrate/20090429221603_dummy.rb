class Dummy < ActiveRecord::Migration
  def self.up
    #add_column :amazon_printers, :product_id, :integer
    #add_column :printers, :manufacturerproducturl, :string
    add_column :printers, :averagereviewrating, :float
    add_column :printers, :totalreviews, :integer
    add_column :cameras, :averagereviewrating, :float
    add_column :cameras, :totalreviews, :integer
    add_column :amazon_printers, :averagereviewrating, :float
    add_column :amazon_printers, :totalreviews, :integer
  end

  def self.down
    #remove_column :cameras, :availability
    #remove_column :printers, :availability
  end
end
