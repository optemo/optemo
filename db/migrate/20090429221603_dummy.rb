class Dummy < ActiveRecord::Migration
  def self.up
    #add_column :amazon_printers, :product_id, :integer
    #add_column :printers, :manufacturerproducturl, :string
  end

  def self.down
    #remove_column :cameras, :availability
    #remove_column :printers, :availability
  end
end
