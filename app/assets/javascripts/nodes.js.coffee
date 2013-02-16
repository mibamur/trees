node = 
	"""
		<div id='node{{id}}' class='node'>
			<strong>
				<p class='title'>{{name}}</p>
			</strong>
			<p class='description'>{{description}}</p>
		</div>
	"""

nodeConnector = 
	#connector: "StateMachine",
	paintStyle: 
		lineWidth:3
		strokeStyle:"#056"
	endpoint:"Blank",
	anchor:"Continuous", #!!
	overlays:[ ["PlainArrow", {location:1, width:20, length:12} ]]

@nodes = 
	init: -> 
		jsPlumb.importDefaults
			DragOptions: 
				cursor: "pointer"
				zIndex: 2000

		window.nodes.growing_tree $('section#workspace').data 'tree'

	growing_tree: (seed)-> 
		$.each seed, (k)-> 
			unless  $(".node[data-id='#{k}']").length > 0
				$('section#workspace').append Mustache.render node, id: k, name: seed[k]['name'], description: seed[k]['description']
		$.each seed, (k,v)-> 
			if v['links'].length > 0
				$.each v['links'], (_, id) -> 
	      	jsPlumb.connect 
	      		source: "node#{k}"
	      		target: "node#{id}"
	      		, nodeConnector

			jsPlumb.draggable $('.node')

$ -> 
	window.nodes.init()
	# id = 1
	# $('a.create').click -> 
	# 	$('section#workspace').append $("<div class='node' id='node#{id}'>")
	# 	jsPlumb.draggable $('.node')

	