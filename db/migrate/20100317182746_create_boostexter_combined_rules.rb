class CreateBoostexterCombinedRules < ActiveRecord::Migration
  def self.up
    create_table :boostexter_combined_rules do |t|
      t.string :fieldname
      t.double :weight
      t.int :cluster_id
      t.int :version
      t.text :yaml_repr

      t.timestamps
      add_index :fieldname :cluster_id :version
    end
  end

  def self.down
    drop_table :boostexter_combined_rules
  end
end
