class CreateBoostexterRules < ActiveRecord::Migration
  def self.up
    create_table :boostexter_rules do |t|
      t.string :fieldname
      t.float :weight
      t.integer :cluster_id
      t.integer :version
      t.text :yaml_repr
      t.string :rule_type

      t.timestamps
    end
  end

  def self.down
    drop_table :boostexter_rules
  end
end
