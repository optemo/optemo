require 'migration_helper'
class CreatePrinters < ActiveRecord::Migration
  extend MigrationHelper
  def self.up
    create_table :printers do |t|
      t.primary_key :id

      addPrinterTableProperties(t)
    end
  end

  def self.down
    drop_table :printers
  end
end
