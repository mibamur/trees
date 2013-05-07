class AddHiddenToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :hidden, :boolean
  end
end