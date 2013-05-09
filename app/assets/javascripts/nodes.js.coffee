node_template = 
  """
    <div id='node{{id}}' class='node' style='top:{{x}}px; left:{{y}}px' data-hidden='{{hidden}}' data-id='{{id}}'>
      <h1 class='title'>{{name}}</h1>
      <textarea class='description'>{{description}}</textarea>
    </div>
  """

control_menu_template = 
  """
    <div class='control vertical-menu'>
      <ul>
        {{#options}}
          <li id='{{.}}' ><a class='typicons-{{.}} {{.}}' title='{{.}}' href="#"></a></li>
        {{/options}}
      </ul>
    </div>
  """

stroke_style = "#ecf0f1"
stroke_style_hover = "#3090bd"

nodeConnector = 
  paintStyle: 
    lineWidth: 2
    strokeStyle: stroke_style
  endpoint: "Blank",
  anchor: "Continuous"
  overlays: [ ["PlainArrow", {location:1, width:20, length:12} ]]
  #connector: ["StateMachine", curviness: 20 ]

@nodes = 
  init: -> 
    jsPlumb.importDefaults 
      Endpoint: "Blank"
      HoverPaintStyle:
        strokeStyle: stroke_style_hover
        lineWidth: 2
      ConnectionOverlays: [[ "Arrow", 
        location: 1
        id: "arrow"
        length: 14
        foldback: 0.8
      ], #["Label",
         #label: "test"
         #id: "label"]
      ]

    nodes.draw_maps()
    nodes.handle_main_menu()
    nodes.handle_connections_delete()
    nodes.update_changes()

  check_updates: (klass) ->
    # need update description for all nodes
    $("#{klass} .description").on 'input', -> 
      id = $(this).parents('.node').data 'id'
      window["node#{id}_changed"] = true

  handle_connections_delete: -> 
    # delete connection 
    jsPlumb.bind "click", (connection) ->
      if confirm 'Delete connection?'
        from = connection.sourceId.replace(/^\D+/,'')
        to = connection.targetId.replace(/^\D+/,'')
        $.ajax(type: 'PUT', url: "/nodes/#{from}", data: { connection: { from: from, to: to, destroy: true }}).done -> 
          jsPlumb.detach connection 

  update_changes: -> 
    interval = setInterval ( -> 
      $('.node').each -> 
        id = $(this).data 'id'
        if window["node#{id}_changed"]
          $.ajax(type: 'PUT', url: "/nodes/#{id}", data: { node: { description: $(this).find('textarea.description').val() }}).done -> 
            window["node#{id}_changed"] = undefined
    ), 10000

  handle_main_menu: -> 
    $('header.main-menu a.create').click -> nodes.create_block()
    $('header.main-menu a.zoom_in').click -> nodes.zoom_workspace(0.1)
    $('header.main-menu a.zoom_out').click -> nodes.zoom_workspace(-0.1)

  create_block: -> 
    $.ajax(type: 'POST', url: "/nodes").done (data)-> 
      $('section#workspace').append $(Mustache.render(node_template, id: data.id, name: data.name, description: data.description, x: 30, y: 0)).addClass 'new-node'
      nodes.draw_control_menu(data.id)
      nodes.rebind_blocks '.new-node'

  draw_control_menu: (id) -> 
    menu_elements = 
      options: ['views', 'edit', 'tick', 'times', 'delete']
    $("#node#{id}").append $(Mustache.render(control_menu_template, menu_elements))
    if $("#node#{id}").data 'hidden'
      $("#node#{id}").toggleClass 'horizontal-menu-on'
      $("#node#{id}").find('.control').addClass('horizontal-menu').removeClass('vertical-menu')
      $("#node#{id}").find('.description').css display: 'none'

  draw_maps: -> 
    #$('section#workspace').html ''
    $.ajax(type: 'GET', url: "/", dataType: 'JSON').done (data)-> 
      # render nodes 
      $.each data, (k)-> 
        unless  $(".node[data-id='#{k}']").length > 0
          $('section#workspace').append Mustache.render node_template, id: k, name: data[k]['name'], description: data[k]['description'], x: data[k]['x'], y: data[k]['y'], hidden: data[k]['hidden']
          nodes.draw_control_menu(k)

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

    # make nodes draggable and few fixes for zoom 
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
        id = ui.helper.data('id')
        # save current position
        $.ajax type: 'PUT', url: "/nodes/#{id}", data: { node: { x: ui.position.top, y: ui.position.left }}

    # delete node
    $(klass).on 'click', '.control a.delete', ->
      id = $(this).parents('.node').data 'id'
      if id and confirm 'Delete node?'
        $.ajax(type: 'DELETE', url: "nodes/#{id}").done ->
          jsPlumb.remove $("#node#{id}")
    false

    # show/hide titles
    $(klass).on 'click', '.control a.views', ->
      id = $(this).parents('.node').data 'id'
      if id 
        $("#node#{id}").find('.description').animate
          height: 'toggle'
        , 100, -> 
          jsPlumb.repaint $("#node#{id}")
          control_menu = $("#node#{id}").find('.control')
          $("#node#{id}").toggleClass 'horizontal-menu-on'
          unless control_menu.hasClass 'horizontal-menu'
            control_menu.addClass('horizontal-menu').removeClass('vertical-menu')
          else 
            control_menu.removeClass('horizontal-menu').addClass('vertical-menu')
          hidden = $("#node#{id}").find('.horizontal-menu').get(0)
          $("#node#{id}").find('.horizontal-menu #edit').css(display: 'inline-block') if hidden 
          $.ajax(type: 'PUT', url: "nodes/#{id}", data: { node: { hidden: if hidden then true else false }})
    false

    # edit title
    $(klass).on 'click', '.control a.edit', -> 
      id = $(this).parents('.node').attr('id').replace(/^\D+/,'')
      if id
        title = $("#node#{id} h1.title")
        old_title = title.html()
        horizontal_menu = $("#node#{id}").find('.control').hasClass 'horizontal-menu'
        title.hide()
        $("#node#{id}").prepend "<input type='text' class='new-title' value='#{old_title}'></input>"
        new_title = $("#node#{id}").find '.new-title'
        new_title.focus()

        if horizontal_menu
          $("#node#{id} #tick, #node#{id} #times").css display: 'inline-block'
        else 
          $("#node#{id} #tick, #node#{id} #times").css display: 'list-item'
        $("#node#{id} #edit").css display: 'none'

        new_title.bind 'keypress', (e) -> 
          $("#node#{id} a.tick").click() if e.keyCode == 13

    $(klass).on 'click', '.control a.tick, .control a.times', -> 
      id = $(this).parents('.node').attr('id').replace(/^\D+/,'')
      if id
        horizontal_menu = $("#node#{id}").find('.control').hasClass 'horizontal-menu'
        title = $("#node#{id} h1.title")
        old_title = title.html()
        new_title = $("#node#{id}").find '.new-title'

        if horizontal_menu
          $("#node#{id} #edit").css display: 'inline-block'
        else
          $("#node#{id} #edit").css display: 'list-item' 
        if $(this).hasClass('tick') and old_title != new_title.val()
          $.ajax type: 'PUT', url: "/nodes/#{id}", data: { node: { name: new_title.val() }}
          title.text new_title.val()
        title.show()
        new_title.remove()
        $("#node#{id} #tick, #node#{id} #times").css display: 'none'

    # make element as source of connection
    $("#{klass} .control").each (i, e) ->
      parent = $(e).parents('.node')
      jsPlumb.makeSource $(e),
        parent: parent
        anchor: "Continuous"
        connectorStyle:
          strokeStyle: stroke_style
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

    nodes.check_updates(klass)

$ -> 
  window.nodes.init()