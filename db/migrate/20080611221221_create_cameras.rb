require 'migration_helper'
class CreateCameras < ActiveRecord::Migration
  extend MigrationHelper
  def self.up
    create_table :cameras do |t|
      t.timestamps
      t.primary_key :id
      
      t.text :title
      addPicStuff(t)
      t.text :detailpageurl
      t.text :manufacturerurl
      
      addIdStuff(t)         # brand/model
      addDimensions(t)      # item & package sizes & weights
      addCameraProperties(t) 
      addReviews(t)
      addPricing(t)
      addPricingCa(t)
    end
    add_index :cameras, :instock
    add_index :cameras, :instock_ca
  end

  def self.down
    drop_table :cameras
  end
end
