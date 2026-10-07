@tool
class_name StoryGraphEditor
extends Control

var graph_nodes: Dictionary[StringName, StoryGraphNode] = { }
var _standard_node_library: StoryNodeLibrary = preload(
	'res://addons/story_nodes/resources/libraries/standard_node_library.tres'
)
var _story_data: StoryData

var _new_node_position: Vector2 = Vector2.ZERO
var _connection_from_node: StringName = &''
var _connection_from_port: int = 0
var _connection_to_node: StringName = &''
var _connection_to_port: int = 0

@onready var graph_edit: GraphEdit = %GraphEdit
@onready var add_node_menu: PopupMenu = %AddNodeMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

	# Standard add node menu
	graph_edit.gui_input.connect(_on_graph_edit_gui_input)
	add_node_menu.id_pressed.connect(_on_add_node_menu_id_pressed)

	# Adding nodes when dragging from other nodes.
	graph_edit.connection_drag_started.connect(_on_connection_drag_started)
	graph_edit.connection_to_empty.connect(_on_connection_drag_ended)
	graph_edit.connection_from_empty.connect(_on_connection_drag_ended)

	# Adding links.
	graph_edit.connection_request.connect(_on_connection_request)

	# Deleting nodes.
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)

	# Deleting links
	graph_edit.right_disconnects = true
	graph_edit.disconnection_request.connect(_on_disconnection_request)

	# Moving nodes.
	graph_edit.end_node_move.connect(_on_node_move)

	# Build the node library
	_populate_add_node_menu()


func set_story_data(data: StoryData) -> void:
	if _story_data == data:
		return

	_story_data = data

	_refresh()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return

	_restore_node_sizes()
	_refresh()


func _restore_deleted_nodes(nodes: Array[StoryNode], links: Array[StoryLink]) -> void:
	for node: StoryNode in nodes:
		_story_data.add_node(node)

	for link: StoryLink in links:
		_story_data.add_link(link.from, link.to, link.from_port, link.to_port)

	_refresh()


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	if nodes.is_empty():
		return

	var undo_redo := _story_data.undo_redo

	undo_redo.create_action('Delete Story Nodes')

	var removed_links: Array[StoryLink] = []
	var removed_nodes: Array[StoryNode] = []

	for link: StoryLink in _story_data.link_list:
		for id: StringName in nodes:
			var node = _story_data.get_node(id)
			if node not in removed_nodes:
				removed_nodes.append(node)
			if link.from == id or link.to == id:
				removed_links.append(link)

	for id: StringName in nodes:
		var story_node: StoryNode = _story_data.get_node(id)

		if story_node == null:
			continue

		undo_redo.add_do_method(_story_data.remove_node.bind(id))

		undo_redo.add_undo_method(_restore_deleted_nodes.bind(removed_nodes, removed_links))

	undo_redo.add_do_method(_refresh)
	undo_redo.add_undo_method(_refresh)

	undo_redo.commit_action()


func _on_graph_edit_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	if not event.pressed:
		return

	if event.button_index != MOUSE_BUTTON_RIGHT:
		return

	_connection_from_node = &''
	_connection_from_port = 0
	_connection_to_node = &''
	_connection_to_port = 0

	_new_node_position = (graph_edit.get_local_mouse_position() + graph_edit.scroll_offset) / graph_edit.zoom
	_show_menu()


func _on_connection_drag_started(from_node: StringName, from_port: int, is_output: bool) -> void:
	if not is_output:
		_connection_to_node = from_node
		_connection_to_port = from_port
		_connection_from_node = &''
		_connection_from_port = 0
		return

	_connection_from_node = from_node
	_connection_from_port = from_port
	_connection_to_node = &''
	_connection_to_port = 0


func _on_connection_drag_ended(
	from_node: StringName,
	from_port: int,
	release_position: Vector2,
) -> void:
	_show_menu()


func _show_menu() -> void:
	_new_node_position = (graph_edit.get_local_mouse_position() + graph_edit.scroll_offset) / graph_edit.zoom

	var screen_position: Vector2 = DisplayServer.mouse_get_position()
	add_node_menu.popup(Rect2(screen_position, Vector2.ZERO))


func _on_node_move() -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	var undo_redo := _story_data.undo_redo

	undo_redo.create_action('Move Story Nodes')

	for id: StringName in graph_nodes:
		var graph_node: StoryGraphNode = graph_nodes.get(id)

		if graph_node == null or graph_node.story_node == null:
			continue

		var story_node: StoryNode = graph_node.story_node
		var old_position: Vector2 = graph_node.story_node.position
		var new_position: Vector2 = graph_node.position_offset

		if old_position == new_position:
			continue

		undo_redo.add_do_property(story_node, 'position', new_position)

		undo_redo.add_undo_property(story_node, 'position', old_position)

	undo_redo.add_do_method(_refresh)
	undo_redo.add_undo_method(_refresh)

	undo_redo.commit_action()


func _refresh() -> void:
	graph_nodes.clear()
	graph_edit.clear_connections()

	for child: Node in graph_edit.get_children():
		if child is GraphNode:
			child.free()

	if _story_data == null:
		push_error('No Selected Story')
		return

	for node: StoryNode in _story_data.node_list:
		var graph_scene: PackedScene = node.graph_scene

		if graph_scene == null:
			var prototype: StoryNode = _standard_node_library.get_node(node.node_id)

			if prototype == null:
				push_error('No node prototype found for "%s"' % node.node_id)
				continue

			graph_scene = prototype.graph_scene

		var graph_node: StoryGraphNode = graph_scene.instantiate() as StoryGraphNode

		if graph_node == null:
			push_error('Graph scene for "%s" is not a StoryGraphNode.' % node.display_name)
			continue

		graph_edit.add_child(graph_node)

		graph_node.set_story_data(_story_data)
		graph_node.set_story_node(node)
		graph_node.ports_changed.connect(_on_ports_changed)

		graph_nodes[node.instance_id] = graph_node

	if is_visible_in_tree():
		_restore_node_sizes()

	await get_tree().process_frame

	_refresh_links()


func _on_ports_changed() -> void:
	graph_edit.clear_connections()

	await get_tree().process_frame

	_refresh_links()


func _refresh_links() -> void:
	if not is_visible_in_tree():
		return

	if _story_data == null:
		push_error('No Selected Story')
		return

	for link: StoryLink in _story_data.link_list:
		var from_node: StoryGraphNode = graph_nodes.get(link.from)
		var to_node: StoryGraphNode = graph_nodes.get(link.to)

		if from_node == null or to_node == null:
			continue

		if link.from_port < 0 or link.from_port >= from_node.get_output_port_count():
			push_error('Invalid output port %d on node %s.' % [link.from_port, from_node.name])
			continue

		if link.to_port < 0 or link.to_port >= to_node.get_input_port_count():
			push_error('Invalid input port %d on node %s.' % [link.to_port, to_node.name])
			continue

		graph_edit.connect_node(from_node.name, link.from_port, to_node.name, link.to_port)


func _on_connection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int,
) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	var undo_redo := _story_data.undo_redo

	undo_redo.create_action('Create Story Link')

	undo_redo.add_do_method(_story_data.add_link.bind(from_node, to_node, from_port, to_port))

	var link: StoryLink = StoryLink.new()
	link.from = from_node
	link.to = to_node
	link.from_port = from_port
	link.to_port = to_port

	undo_redo.add_undo_method(_story_data.remove_link.bind(link))

	undo_redo.add_do_method(_refresh)
	undo_redo.add_undo_method(_refresh)

	undo_redo.commit_action()


func _on_disconnection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int,
) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	var link := _story_data.get_link(from_node, to_node, from_port, to_port)

	if link == null:
		push_error('Link does not exist.')
		return
	var undo_redo := _story_data.undo_redo

	undo_redo.create_action('Delete Story Link')

	undo_redo.add_do_method(_story_data.remove_link.bind(link))

	undo_redo.add_undo_method(_story_data.add_link.bind(from_node, to_node, from_port, to_port))

	undo_redo.add_do_method(_refresh)
	undo_redo.add_undo_method(_refresh)

	undo_redo.commit_action()


func _populate_add_node_menu() -> void:
	add_node_menu.clear()

	var menu_id: int = 0

	for node: StoryNode in _standard_node_library.node_list:
		add_node_menu.add_item(node.display_name, menu_id)
		add_node_menu.set_item_metadata(menu_id, node)
		menu_id += 1


func _on_add_node_menu_id_pressed(id: int) -> void:
	var node: Variant = add_node_menu.get_item_metadata(id)

	if node is not StoryNode:
		push_error('Invalid node from add node menu.')
		return

	_add_node_from_node(node)


func _add_node_from_node(node: StoryNode) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	var story_node: StoryNode = node.duplicate(true)
	story_node.instance_id = _new_instance_id(story_node.node_id)
	story_node.position = _new_node_position

	var undo_redo := _story_data.undo_redo

	undo_redo.create_action('Add Story Node')

	undo_redo.add_do_method(_story_data.add_node.bind(story_node))
	undo_redo.add_undo_method(_story_data.remove_node.bind(story_node.instance_id))

	if not _connection_from_node.is_empty():
		_on_connection_request(
			_connection_from_node,
			_connection_from_port,
			story_node.instance_id,
			0,
		)
		_connection_from_node = &''
		_connection_from_port = 0

	if not _connection_to_node.is_empty():
		_on_connection_request(story_node.instance_id, 0, _connection_to_node, _connection_to_port)
		_connection_to_node = &''
		_connection_to_port = 0

	undo_redo.add_do_method(_refresh)
	undo_redo.add_undo_method(_refresh)

	undo_redo.commit_action()


func _new_instance_id(base_name: String = 'node') -> StringName:
	var result: StringName
	var index := 1

	while _story_data.has_node(base_name + str(index)):
		index += 1

	return (base_name + str(index)) as StringName


func _restore_node_sizes() -> void:
	for id: StringName in graph_nodes:
		var graph_node: StoryGraphNode = graph_nodes[id]
		graph_node.restore_saved_size()
