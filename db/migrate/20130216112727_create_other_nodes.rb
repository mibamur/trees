class CreateOtherNodes < ActiveRecord::Migration
  def up
    create_table :other_nodes do |t|
      t.integer :other_node_id
      t.integer :node_id
    end
  end
 
  def down
    drop_table :other_nodes
  end
end
