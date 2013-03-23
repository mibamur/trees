class Node < ActiveRecord::Base
  attr_accessible :name, :description, :x, :y
  has_and_belongs_to_many :nodes, class_name: 'Node', join_table: 'other_nodes', foreign_key: 'node_id', association_foreign_key: 'other_node_id' , uniq: true

  def self.links_of nodes
    {}.tap do |hash|
      nodes.each do |node|
        hash[node.id] = {}
        hash[node.id][:links] = []
        hash[node.id][:name] = node.name
        hash[node.id][:description] = node.description
        hash[node.id][:x] = node.x || 0
        hash[node.id][:y] = node.y || 0
        node.nodes.each do |link|
          hash[node.id][:links] << link.id    
        end
      end
    end
  end

end
