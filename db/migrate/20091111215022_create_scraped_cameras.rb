require 'migration_helper'
class CreateScrapedCameras < ActiveRecord::Migration
  extend MigrationHelper
  def self.up
    create_table :scraped_cameras do |t|
      t.timestamps
      t.primary_key :id
      
      t.text :title
      t.text :imageurl
      t.text :detailpageurl
      t.text :manufacturerurl
      t.datetime :scrapedat 
      
      addIdStuff(t)         # brand/model
      addDimensions(t)      # item & package sizes & weights
      addCameraProperties(t) 
      addReviews(t)
      
      #???"listpriceint"??
      #t.string :warranty?? -- or should this go in RO?
    end
  end

  def self.down
    drop_table :scraped_cameras
  end
end