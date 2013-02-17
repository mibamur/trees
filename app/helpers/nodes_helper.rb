module NodesHelper

	def links_of nodes
		hash = {}
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
		hash.to_json
	end

end
