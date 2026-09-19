@tool
class_name StoryGraphEditor
extends Control

var graph_nodes: Dictionary[StringName, StoryGraphNode] = { }
var _standard_node_library: StoryNodeLibrary = preload(
	'res://addons/story_nodes/resources/libraries/standard_node_library.tres'
)
var _story_data: StoryData

@onready var graph_edit: GraphEdit = %GraphEdit
@onready var add_node_menu: PopupMenu = %AddNodeMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph_edit.right_disconnects = true
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.end_node_move.connect(_on_node_move)
	graph_edit.gui_input.connect(_on_graph_edit_gui_input)

	add_node_menu.id_pressed.connect(_on_add_node_menu_id_pressed)

	_populate_add_node_menu()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_story_data(data: StoryData) -> void:
	_story_data = data
	_refresh()


func _on_graph_edit_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	if not event.pressed:
		return

	if event.button_index != MOUSE_BUTTON_RIGHT:
		return

	add_node_menu.position = Vector2(event.global_position)
	add_node_menu.popup()


func _on_node_move() -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	for id: StringName in graph_nodes:
		var graph_node: StoryGraphNode = graph_nodes[id]

		if graph_node.story_node == null:
			continue

		graph_node.story_node.position = graph_node.position_offset
		_story_data.mark_changed()


func _refresh() -> void:
	graph_nodes.clear()

	for child: Node in graph_edit.get_children():
		if child is GraphNode:
			child.queue_free()

	if _story_data == null:
		push_error('No Selected Story')
		return

	for node: StoryNode in _story_data.node_list:
		var prototype: StoryNode = _standard_node_library.get_node(node.node_id)

		if prototype == null:
			push_error('No node prototype found for "%s"' % node.node_id)
			continue

		var graph_node: StoryGraphNode = prototype.graph_scene.instantiate() as StoryGraphNode

		if graph_node == null:
			push_error('Graph scene for "%s" is not a StoryGraphNode.' % prototype.display_name)
			continue

		graph_edit.add_child(graph_node)

		graph_node.set_story_node(node)

		graph_nodes[node.instance_id] = graph_node

	await get_tree().process_frame

	_refresh_links()


func _refresh_links() -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	for link: StoryLink in _story_data.link_list:
		var from_node: StoryGraphNode = graph_nodes.get(link.from)
		var to_node: StoryGraphNode = graph_nodes.get(link.to)

		if from_node == null or to_node == null:
			continue

		graph_edit.connect_node(from_node.name, link.from_port, to_node.name, link.to_port)


func _get_graph_node(id: StringName) -> StoryGraphNode:
	for child: Node in graph_edit.get_children():
		if child is StoryGraphNode:
			if child.story_node != null and child.story_node.instance_id == id:
				return child

	return null


func _on_connection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int,
) -> void:
	if _story_data == null:
		push_error('No Selected Story')
		return

	var link := _story_data.add_link(from_node, to_node, from_port, to_port)

	if link == null:
		push_error('Could not create link')
		return

	graph_edit.connect_node(from_node, from_port, to_node, to_port)


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

	_story_data.remove_link(link)

	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)


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
	story_node.instance_id = _new_instance_id()

	_story_data.add_node(story_node)

	_refresh()


func _new_instance_id() -> StringName:
	var base_name := 'node'
	var result: StringName

	result = base_name
	var index := 0

	while _story_data.has_node(result):
		result = base_name + str(index)
		index += 1

	return result as StringName
