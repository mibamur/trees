node = 
	"""
		<div id='node{{id}}' class='node' style='top:{{x}}px; left:{{y}}px'>
			<a class='close' href='#'>&times;</a>
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

		$('a.close').click ->
			id = $(this).parent().attr('id').replace(/^\D+/,'')
			if id and confirm 'are you sure?'
				$("#node#{id}").remove()
				$.ajax type: 'DELETE', url: "nodes/#{id}"
		false

	growing_tree: (seed)-> 
		$.each seed, (k)-> 
			unless  $(".node[data-id='#{k}']").length > 0
				$('section#workspace').append Mustache.render node, id: k, name: seed[k]['name'], description: seed[k]['description'], x: seed[k]['x'], y: seed[k]['y']
		$.each seed, (k,v)-> 
			if v['links'].length > 0
				$.each v['links'], (_, id) -> 
	      	jsPlumb.connect 
	      		source: "node#{k}"
	      		target: "node#{id}"
	      		, nodeConnector

			jsPlumb.draggable $('.node'), 
				stop: (e, ui)-> 
					id = ui.helper.attr('id').replace(/^\D+/,'')
					console.log id
					$.ajax type: 'PUT', url: "/nodes/#{id}", data: { node: { x: ui.position.top, y: ui.position.left }}

$ -> 
	window.nodes.init()