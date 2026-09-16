@tool
class_name StoryGraphEditor
extends Control

const STORY_GRAPH_NODE := preload('res://addons/story_nodes/nodes/story_graph_node.tscn')
const START_NODE := preload('res://addons/story_nodes/nodes/start_graph_node.tscn')

var graph_nodes: Dictionary[StringName, StoryGraphNode] = { }
var _story_data: StoryData

@onready var graph_edit: GraphEdit = $GraphEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph_edit.right_disconnects = true
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.end_node_move.connect(_on_node_move)


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
