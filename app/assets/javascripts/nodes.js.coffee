node_template = 
  """
    <div id='node{{id}}' class='node' style='top:{{x}}px; left:{{y}}px'>
      <h1 class='title'>{{name}}</h1>
      <textarea class='description' style='display:{{horizontal}}'>{{description}}</textarea>
    </div>
  """

control_menu_template = 
  """
    <div class='control {{horizontal}}'>
      <ul>
        {{#options}}
          <li id='{{.}}' ><a class='typicons-{{.}} {{.}}' title='{{.}}' href="#"></a></li>
        {{/options}}
      </ul>
    </div>
  """

nodeConnector = 
  paintStyle: 
    lineWidth: 2
    strokeStyle: "#ecf0f1"
  #endpoint: "Blank",
  anchor: "Continuous"
  overlays: [ ["PlainArrow", {location:1, width:20, length:12} ]]
  #connector: ["StateMachine", curviness: 20 ]

@nodes = 
  init: -> 
    jsPlumb.importDefaults
      Endpoint: ["Dot",
        radius: 2
      ]
      HoverPaintStyle:
        strokeStyle: "#3090bd"
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
    nodes.handle_main_menu()
    #nodes.update_changes()

    # delete connection 
    jsPlumb.bind "click", (connection) ->
      if confirm 'are u sure ?'
        from = connection.sourceId.replace(/^\D+/,'')
        to = connection.targetId.replace(/^\D+/,'')
        $.ajax(type: 'PUT', url: "/nodes/#{from}", data: { connection: { from: from, to: to, destroy: true }}).done -> 
          jsPlumb.detach connection 

  update_changes: -> 
    interval = setInterval ( -> 
      $('.node').each -> 
        if window[$(this).attr('id')]
          id = $(this).attr('id').replace(/^\D+/,'')
          $.ajax(type: 'PUT', url: "/nodes/#{id}", data: { node: { description: $(this).find('textarea.description').val() }}).done -> 
            window[$(this).attr('id')] = undefined
    ), 10000

  handle_main_menu: -> 
    $('header.main-menu a.create').click -> nodes.create_block()
    $('header.main-menu a.zoom_in').click -> nodes.zoom_workspace(0.1)
    $('header.main-menu a.zoom_out').click -> nodes.zoom_workspace(-0.1)

  create_block: -> 
    $.ajax(type: 'POST', url: "/nodes").done (data)-> 
      $('section#workspace').append $(Mustache.render(node_template, id: data.id, name: data.name, description: data.description, x: 30, y: 0)).addClass 'new-node'
      nodes.rebind_blocks '.new-node'
      nodes.draw_control_menu(data.id)

  draw_control_menu: (id, hidden) -> 
    menu_elements = 
      options: ['views', 'edit', 'tick', 'times', 'delete']
      horizontal: if hidden == true then 'horizontal-menu' else ''
    $("#node#{id}").append $(Mustache.render(control_menu_template, menu_elements))

  # create all nodes 
  growing_tree: -> 
    #$('section#workspace').html ''
    $.ajax(type: 'GET', url: "/", dataType: 'JSON').done (data)-> 
      # render nodes 
      $.each data, (k)-> 
        unless  $(".node[data-id='#{k}']").length > 0
          $('section#workspace').append Mustache.render node_template, id: k, name: data[k]['name'], description: data[k]['description'], x: data[k]['x'], y: data[k]['y'], horizontal: if data[k]['hidden'] == true then 'none' else ''
          nodes.draw_control_menu(k, data[k]['hidden'])

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
    if window.current_zoom > 0.4
      $('section#workspace').css(zoom: window.current_zoom) 
    else 
      window.current_zoom = 0.4
    jsPlumb.repaintEverything()

  rebind_blocks: (klass) -> 
    pointY = 0
    pointX = 0

    # make nodes draggable 
    jsPlumb.draggable $(klass), 
      handle: '.title'
      start: (e, ui)-> 
        pointY = e.pageY / window.current_zoom - parseInt $(e.target).css('top')
        pointX = e.pageX / window.current_zoom - parseInt $(e.target).css('left')
      drag: (e, ui)-> 
        if window.current_zoom
          ui.position.top = Math.round(e.pageY / window.current_zoom - pointY) 
          ui.position.left = Math.round(e.pageX / window.current_zoom - pointX)
          jsPlumb.repaint $(e.target).attr 'id'
      stop: (e, ui)-> 
        jsPlumb.repaint $(e.target).attr 'id'
        id = ui.helper.attr('id').replace(/^\D+/,'')
        # save current position
        $.ajax type: 'PUT', url: "/nodes/#{id}", data: { node: { x: ui.position.top, y: ui.position.left }}

    # delete node
    $(klass).on 'click', '.control a.delete', ->
      id = $(this).parents('.node').attr('id').replace(/^\D+/,'')
      if id and confirm 'are you sure?'
        jsPlumb.detachAllConnections "node#{id}"
        $("#node#{id}").remove()
        $.ajax type: 'DELETE', url: "nodes/#{id}"
    false

    # show/hide titles
    $(klass).on 'click', '.control a.views', ->
      id = $(this).parents('.node').attr('id').replace(/^\D+/,'')
      if id 
        $("#node#{id}").find('.description').animate
          height: 'toggle'
        , 100, -> 
          jsPlumb.repaint $("#node#{id}")
          control_menu = $("#node#{id}").find('.control')
          control_menu.toggleClass 'horizontal-menu'
          $("#node#{id}").toggleClass 'horizontal-menu-on'
          hidden = $("#node#{id}").find('.horizontal-menu').get(0)
          $("#node#{id}").find('.horizontal-menu #edit').css(display: 'inline-block') if hidden 
          $.ajax(type: 'PUT', url: "nodes/#{id}", data: { node: { hidden: if hidden != undefined then true else false }})
    false

    # edit title
    $(klass).on 'click', '.control a.edit', -> 
      id = $(this).parents('.node').attr('id').replace(/^\D+/,'')
      if id
        title = $("#node#{id} h1.title")
        old_title = title.html()
        horizontal_menu = $("#node#{id}").find('.control').hasClass 'horizontal-menu'
        title.hide()
        $("#node#{id} .new-title").remove()
        $("#node#{id}").prepend "<input type='text' class='new-title' value='#{old_title}'></input>"
        $("#node#{id} .new-title").focus()
        if horizontal_menu
          $("#node#{id} #tick, #node#{id} #times").css display: 'inline-block'
        else 
          $("#node#{id} #tick, #node#{id} #times").css display: 'list-item'
        $("#node#{id} #edit").css display: 'none'
        $("#node#{id} #tick, #node#{id} #times").click -> 
          if horizontal_menu
            $("#node#{id} #edit").css display: 'inline-block'
          else
            $("#node#{id} #edit").css display: 'list-item'
          if $(this).attr('id') == 'tick'
            $.ajax(type: 'PUT', url: "/nodes/#{id}", data: { node: { name: $("#node#{id} .new-title").val() }}).done -> 
            title.text $("#node#{id} .new-title").val()
          title.show()
          $("#node#{id} .new-title").remove()
          $("#node#{id} #tick, #node#{id} #times").css display: 'none'

    # make element as source of connection
    $("#{klass} .control").each (i, e) ->
      parent = $(e).parents('.node')
      jsPlumb.makeSource $(e),
        parent: parent
        anchor: "Continuous"
        #connector: ["StateMachine", curviness: 20]
        connectorStyle:
          strokeStyle: "#ecf0f1"
          lineWidth: 2
        maxConnections: -1

    # make nodes as connection target
    jsPlumb.makeTarget jsPlumb.getSelector(klass),
      dropOptions:
        hoverClass: "dragHover"
      anchor: "Continuous"
      isTarget: true
      beforeDrop: (params) ->
        #if confirm "Connect #{params.sourceId} to #{params.targetId}?"
        from = params.sourceId.replace(/^\D+/,'')
        to = params.targetId.replace(/^\D+/,'')
        unless from == to 
          # save connection 
          $.ajax type: 'PUT', url: "/nodes/#{from}", data: { connection: { from: from, to: to, destroy: false }}
        else 
          false 

    # need update description for next nodes
    $('.node textarea').on 'input', -> 
      window[$(this).parents('.node').attr('id')] = true

$ -> 
  window.nodes.init()