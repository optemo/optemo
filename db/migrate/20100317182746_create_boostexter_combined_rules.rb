class CreateBoostexterCombinedRules < ActiveRecord::Migration
  def self.up
    create_table :boostexter_combined_rules do |t|
      t.string :fieldname
      t.double :weight
      t.int :cluster_id
      t.int :version
      t.text :yaml_repr

      t.timestamps
      t.string :rule_type
    end
    add_index :boostexter_combined_rules, :fieldname
    add_index :boostexter_combined_rules, :cluster_id
    add_index :boostexter_combined_rules, :version
  end

  def self.down
    drop_table :boostexter_combined_rules
  end
end
