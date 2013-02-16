class Node < ActiveRecord::Base
  attr_accessible :name, :description
  has_and_belongs_to_many :nodes, class_name: 'Node', join_table: 'other_nodes', foreign_key: 'node_id', association_foreign_key: 'other_node_id' , uniq: true
end
