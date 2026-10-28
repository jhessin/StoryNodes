@tool
class_name StoryGraphEditor
extends Control
## Shows a StoryData as a GraphEdit. The graph is built once per story and then
## kept in step through StoryData's granular signals, so an edit only touches
## the nodes and connections it actually changed.
##
## Every edit goes through StoryData's public API (which records undo/redo);
## this class never mutates story data directly.

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

## Nodes whose connections must be re-checked on the next flush.
var _dirty_link_nodes: Dictionary[StringName, bool] = { }
var _link_flush_queued: bool = false

@onready var graph_edit: GraphEdit = %GraphEdit
@onready var add_node_menu: PopupMenu = %AddNodeMenu


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


## Shows `data`. This is the only full rebuild; later edits update in place.
func set_story_data(data: StoryData) -> void:
	if _story_data == data:
		return

	if _story_data != null:
		_disconnect_story(_story_data)

	_story_data = data

	if _story_data != null:
		_connect_story(_story_data)

	_rebuild()


## ===
## Story signals -> targeted updates
## ===
func _connect_story(data: StoryData) -> void:
	data.node_added.connect(_on_node_added)
	data.node_removed.connect(_on_node_removed)
	data.link_added.connect(_on_link_added)
	data.link_removed.connect(_on_link_removed)
	data.links_changed.connect(_mark_links_dirty)


func _disconnect_story(data: StoryData) -> void:
	data.node_added.disconnect(_on_node_added)
	data.node_removed.disconnect(_on_node_removed)
	data.link_added.disconnect(_on_link_added)
	data.link_removed.disconnect(_on_link_removed)
	data.links_changed.disconnect(_mark_links_dirty)


func _on_node_added(node: StoryNode) -> void:
	_add_graph_node(node)
	_mark_links_dirty(node.instance_id)


func _on_node_removed(id: StringName) -> void:
	var graph_node: StoryGraphNode = graph_nodes.get(id)

	if graph_node == null:
		return

	graph_nodes.erase(id)

	# Drop its connections now; the surviving ends are re-checked by the
	# link_removed signals.
	for connection: Dictionary in graph_edit.get_connection_list():
		if connection.from_node == graph_node.name or connection.to_node == graph_node.name:
			graph_edit.disconnect_node(
				connection.from_node,
				connection.from_port,
				connection.to_node,
				connection.to_port,
			)

	StoryGraphNode.discard(graph_node)


func _on_link_added(link: StoryLink) -> void:
	_mark_links_dirty(link.from)
	_mark_links_dirty(link.to)


func _on_link_removed(link: StoryLink) -> void:
	_mark_links_dirty(link.from)
	_mark_links_dirty(link.to)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return

	_restore_node_sizes()
	_queue_link_flush()


## ===
## Building the graph
## ===
func _rebuild() -> void:
	graph_nodes.clear()
	_dirty_link_nodes.clear()
	graph_edit.clear_connections()

	for child: Node in graph_edit.get_children():
		if child is GraphNode:
			StoryGraphNode.discard(child)

	if _story_data == null:
		return

	for node: StoryNode in _story_data.node_list:
		_add_graph_node(node)
		_mark_links_dirty(node.instance_id)

	if is_visible_in_tree():
		_restore_node_sizes()


func _add_graph_node(node: StoryNode) -> StoryGraphNode:
	var existing: StoryGraphNode = graph_nodes.get(node.instance_id)

	if existing != null:
		return existing

	var graph_scene: PackedScene = node.graph_scene

	if graph_scene == null:
		var prototype: StoryNode = _standard_node_library.get_node(node.node_id)

		if prototype == null:
			push_error('No node prototype found for "%s"' % node.node_id)
			return null

		graph_scene = prototype.graph_scene

	var graph_node: StoryGraphNode = graph_scene.instantiate() as StoryGraphNode

	if graph_node == null:
		push_error('Graph scene for "%s" is not a StoryGraphNode.' % node.display_name)
		return null

	graph_edit.add_child(graph_node)

	graph_node.set_story_data(_story_data)
	graph_node.set_story_node(node)
	graph_node.ports_changed.connect(_mark_links_dirty.bind(node.instance_id))

	graph_nodes[node.instance_id] = graph_node

	if is_visible_in_tree():
		graph_node.restore_saved_size()

	return graph_node


func _restore_node_sizes() -> void:
	for id: StringName in graph_nodes:
		var graph_node: StoryGraphNode = graph_nodes[id]
		graph_node.restore_saved_size()


## ===
## Connections
## ===
func _mark_links_dirty(id: StringName) -> void:
	_dirty_link_nodes[id] = true
	_queue_link_flush()


func _queue_link_flush() -> void:
	if _link_flush_queued:
		return

	_link_flush_queued = true
	_flush_links.call_deferred()


func _flush_links() -> void:
	if not is_inside_tree():
		_link_flush_queued = false
		return

	# Graph nodes work out their port counts when laid out, one frame later.
	await get_tree().process_frame

	_link_flush_queued = false

	# Stay dirty while hidden; _on_visibility_changed flushes again.
	if _story_data == null or not is_visible_in_tree():
		return

	var ids: Array[StringName] = _dirty_link_nodes.keys()
	_dirty_link_nodes.clear()

	for id: StringName in ids:
		_reconcile_links(id)


## Makes the GraphEdit connections touching `id` match the story's links.
func _reconcile_links(id: StringName) -> void:
	if not graph_nodes.has(id):
		return

	var wanted: Dictionary[String, StoryLink] = { }

	for link: StoryLink in _story_data.link_list:
		if link.from == id or link.to == id:
			wanted[_connection_key(link.from, link.from_port, link.to, link.to_port)] = link

	for connection: Dictionary in graph_edit.get_connection_list():
		if connection.from_node != id and connection.to_node != id:
			continue

		var key: String = _connection_key(
			connection.from_node,
			connection.from_port,
			connection.to_node,
			connection.to_port,
		)

		if wanted.has(key):
			wanted.erase(key) # Already drawn.
		else:
			graph_edit.disconnect_node(
				connection.from_node,
				connection.from_port,
				connection.to_node,
				connection.to_port,
			)

	for link: StoryLink in wanted.values():
		_connect_link(link)


func _connect_link(link: StoryLink) -> void:
	var from_node: StoryGraphNode = graph_nodes.get(link.from)
	var to_node: StoryGraphNode = graph_nodes.get(link.to)

	if from_node == null or to_node == null:
		return

	if link.from_port < 0 or link.from_port >= from_node.get_output_port_count():
		push_warning('Invalid output port %d on node %s.' % [link.from_port, from_node.name])
		return

	if link.to_port < 0 or link.to_port >= to_node.get_input_port_count():
		push_warning('Invalid input port %d on node %s.' % [link.to_port, to_node.name])
		return

	graph_edit.connect_node(from_node.name, link.from_port, to_node.name, link.to_port)


func _connection_key(from: StringName, from_port: int, to: StringName, to_port: int) -> String:
	return '%s|%d|%s|%d' % [from, from_port, to, to_port]


## ===
## User actions -> StoryData API (which records undo/redo)
## ===
func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	_story_data.remove_nodes(nodes)


func _on_node_move() -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	var positions: Dictionary[StringName, Vector2] = { }

	for id: StringName in graph_nodes:
		var graph_node: StoryGraphNode = graph_nodes[id]

		if graph_node.story_node == null:
			continue

		if graph_node.story_node.position != graph_node.position_offset:
			positions[id] = graph_node.position_offset

	if not positions.is_empty():
		_story_data.move_nodes(positions)


func _on_connection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int,
) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	if _story_data.has_link(from_node, to_node, from_port, to_port):
		return

	_story_data.add_link(from_node, to_node, from_port, to_port)


func _on_disconnection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int,
) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	var link: StoryLink = _story_data.get_link(from_node, from_port, to_node, to_port)

	if link == null:
		push_error('Link does not exist.')
		return

	_story_data.remove_link(link)


func _add_node_from_node(node: StoryNode) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	var story_node: StoryNode = node.duplicate(true)
	story_node.instance_id = _new_instance_id(story_node.node_id)
	story_node.position = _new_node_position

	# Take the pending connection (from dragging out of a port) and clear it.
	var from_id: StringName = _connection_from_node
	var from_port: int = _connection_from_port
	var to_id: StringName = _connection_to_node
	var to_port: int = _connection_to_port

	_connection_from_node = &''
	_connection_from_port = 0
	_connection_to_node = &''
	_connection_to_port = 0

	var build: Callable = func() -> void:
		_story_data.add_node(story_node)

		if not from_id.is_empty():
			_story_data.add_link(from_id, story_node.instance_id, from_port, 0)

		if not to_id.is_empty():
			_story_data.add_link(story_node.instance_id, to_id, 0, to_port)

	_story_data.transact('Add Story Node', build)


func _new_instance_id(base_name: String = 'node') -> StringName:
	var index := 1

	while _story_data.has_node(base_name + str(index)):
		index += 1

	return (base_name + str(index)) as StringName


## ===
## Add-node menu
## ===
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
