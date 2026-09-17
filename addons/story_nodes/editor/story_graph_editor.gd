@tool
class_name StoryGraphEditor
extends Control

const STORY_GRAPH_NODE := preload('res://addons/story_nodes/nodes/story_graph_node.tscn')
const START_NODE := preload('res://addons/story_nodes/nodes/start_graph_node.tscn')

var graph_nodes: Dictionary[StringName, StoryGraphNode] = { }
var _standard_node_library: StandardNodeLibrary = StandardNodeLibrary.new()
var _story_data: StoryData

@onready var graph_edit: GraphEdit = %GraphEdit
@onready var add_node_menu: PopupMenu = %AddNodeMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph_edit.right_disconnects = true
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.end_node_move.connect(_on_node_move)

	add_node_menu.id_pressed.connect(_on_add_node_menu_id_pressed)

	_populate_add_node_menu()
	add_node_menu.popup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_story_data(data: StoryData) -> void:
	_story_data = data
	_refresh()


func _on_node_move() -> void:
	if _story_data == null:
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
		return

	for node: StoryNode in _story_data.node_list:
		var graph_node: StoryGraphNode

		if node.id == _story_data.START_NODE_ID:
			graph_node = START_NODE.instantiate() as StoryGraphNode
		else:
			graph_node = STORY_GRAPH_NODE.instantiate() as StoryGraphNode

		graph_edit.add_child(graph_node)

		graph_node.set_story_node(node)

		graph_nodes[node.id] = graph_node

	await get_tree().process_frame

	_refresh_links()


func _refresh_links() -> void:
	if _story_data == null:
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
			if child.story_node != null and child.story_node.id == id:
				return child

	return null


func _on_connection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int,
) -> void:
	if _story_data == null:
		return

	var link := _story_data.add_link(from_node, to_node, from_port, to_port)

	if link == null:
		return

	graph_edit.connect_node(from_node, from_port, to_node, to_port)


func _on_disconnection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int,
) -> void:
	if _story_data == null:
		return

	var link := _story_data.get_link(from_node, to_node, from_port, to_port)

	if link == null:
		return

	_story_data.remove_link(link)

	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)


func _populate_add_node_menu() -> void:
	add_node_menu.clear()

	var menu_id: int = 0

	for definition: StoryNodeDefinition in _standard_node_library.node_list:
		if not definition.instantiable:
			continue

		add_node_menu.add_item(definition.display_name, menu_id)
		add_node_menu.set_item_metadata(menu_id, definition)
		menu_id += 1


func _on_add_node_menu_id_pressed(id: int) -> void:
	var definition: StoryNodeDefinition = add_node_menu.get_item_metadata(id)

	_add_node_from_definition(definition)


func _add_node_from_definition(definition: StoryNodeDefinition) -> void:
	if _story_data == null:
		return

	var story_node: StoryNode = definition.story_node_script.new()

	if story_node == null:
		push_error('Unable to create story node.')
		return

	# TODO: Add the node to _story_data
	_story_data.add_node(story_node)

	_refresh()
