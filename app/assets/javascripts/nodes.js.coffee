node = 
	"""
		<div id='node{{id}}' class='node' style='top:{{x}}px; left:{{y}}px'>
			<div class='node-header'>
				<div class='connector'></div>
				<a class='close' href='#'>&times;</a>
				<span class='title'>{{name}}</span>
			</div>
			<p class='description'>{{description}}</p>
		</div>
	"""

nodeConnector = 
	paintStyle: 
		lineWidth: 2
		strokeStyle: "#42a62c"
	#endpoint: "Blank",
	anchor: "Continuous"
	overlays: [ ["PlainArrow", {location:1, width:20, length:12} ]]
	connector: ["StateMachine", curviness: 20 ]

@nodes = 
	init: -> 
		jsPlumb.importDefaults
		  Endpoint: ["Dot",
		    radius: 2
		  ]
		  HoverPaintStyle:
		    strokeStyle: "#42a62c"
		    lineWidth: 2
		  ConnectionOverlays: [["Arrow",
		    location: 1
		    id: "arrow"
		    length: 14
		    foldback: 0.8
		  ], #["Label",
		     #label: "test"
		     #id: "label"]
		  ]

		nodes.growing_tree()
		$('header.main-menu a.create').click -> nodes.create_block()
		$('header.main-menu a.zoom_in').click -> nodes.zoom_workspace(0.1)
		$('header.main-menu a.zoom_out').click -> nodes.zoom_workspace(-0.1)

		# delete connection 
		jsPlumb.bind "click", (connection) ->
  		jsPlumb.detach connection 

	create_block: -> 
		$.ajax(type: 'POST', url: "/nodes").done (data)-> 
			$('section#workspace').append $(Mustache.render(node, id: data.id, name: data.name, description: data.description, x: 0, y: 0)).addClass 'new-node'
			nodes.rebind_blocks '.new-node'

	# create all nodes 
	growing_tree: -> 
		#$('section#workspace').html ''
		$.ajax(type: 'GET', url: "/", dataType: 'JSON').done (data)-> 
			# render nodes 
			$.each data, (k)-> 
				unless  $(".node[data-id='#{k}']").length > 0
					$('section#workspace').append Mustache.render node, id: k, name: data[k]['name'], description: data[k]['description'], x: data[k]['x'], y: data[k]['y']

			# render connections 
			$.each data, (k,v)-> 
				if v['links'].length > 0
					$.each v['links'], (_, id) -> 
		 	    	jsPlumb.connect 
		 	     		source: "node#{k}"
		 	     		target: "node#{id}"
		 	     		, nodeConnector

	  	nodes.rebind_blocks '.node'

	zoom_workspace: (i)-> 
		window.current_zoom = parseInt($('section#workspace').css 'zoom') unless window.current_zoom
		window.current_zoom += i 
		$('section#workspace').css zoom: window.current_zoom

	rebind_blocks: (klass) -> 
		# make nodes draggable 
		jsPlumb.draggable $(klass), 
			stop: (e, ui)-> 
				id = ui.helper.attr('id').replace(/^\D+/,'')
				# save current position
				$.ajax type: 'PUT', url: "/nodes/#{id}", data: { node: { x: ui.position.top, y: ui.position.left }}

		# delete node
		$(klass).on 'click', 'a.close', ->
			id = $(this).parents('.node').attr('id').replace(/^\D+/,'')
			if id and confirm 'are you sure?'
				jsPlumb.detachAllConnections "node#{id}"
				$("#node#{id}").remove()
				$.ajax type: 'DELETE', url: "nodes/#{id}"
		false

	 	# make element as source of connection
		$("#{klass} .connector").each (i, e) ->
		  parent = $(e).parents('.node')
		  jsPlumb.makeSource $(e),
		    parent: parent
		    anchor: "Continuous"
		    connector: ["StateMachine",
		      curviness: 20
		    ]
		    connectorStyle:
		      strokeStyle: "#42a62c"
		      lineWidth: 2
		    maxConnections: -1

		# make nodes as connection target
		jsPlumb.makeTarget jsPlumb.getSelector(klass),
		  dropOptions:
		    hoverClass: "dragHover"
		  anchor: "Continuous"
		  isTarget: true
		  beforeDrop: (params) ->
		    if confirm "Connect #{params.sourceId} to #{params.targetId}?"
		    	from = params.sourceId.replace(/^\D+/,'')
		    	to = params.targetId.replace(/^\D+/,'')
		    	# save connection 
		    	$.ajax type: 'PUT', url: "/nodes/#{from}", data: { connection: { from: from, to: to }}

$ -> 
	window.nodes.init()