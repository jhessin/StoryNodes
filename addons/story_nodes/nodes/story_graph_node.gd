@tool
class_name StoryGraphNode
extends GraphNode

signal ports_changed

var story_node: StoryNode
var story_data: StoryData

var history: StoryHistory:
	get:
		if story_data == null:
			return null
		return story_data.history


# var _restoring_size: bool = false
func _ready() -> void:
	if not resize_end.is_connected(_on_resize_end):
		resize_end.connect(_on_resize_end)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	pass


func set_story_node(node: StoryNode) -> void:
	if story_node != null:
		if story_node.changed.is_connected(_on_story_node_changed):
			story_node.changed.disconnect(_on_story_node_changed)

	story_node = node

	if story_node == null:
		push_error('Story node should be set when using a StoryGraphNode')
		return

	if not story_node.changed.is_connected(_on_story_node_changed):
		story_node.changed.connect(_on_story_node_changed)

	if not story_node.instance_id.is_empty():
		name = String(story_node.instance_id)

	title = story_node.display_name + '(' + story_node.instance_id + ')'
	position_offset = story_node.position
	set_deferred('size', story_node.size)


func set_story_data(data: StoryData) -> void:
	story_data = data


func get_story_data() -> StoryData:
	return story_data


func get_story_node() -> StoryNode:
	return story_node


func restore_saved_size() -> void:
	if story_node == null:
		return

	if story_node.size != Vector2.ZERO:
		# _restoring_size = true
		set_deferred('size', story_node.size)
		# _restoring_size = false


func _on_resize_end(new_size: Vector2) -> void:
	if story_node == null:
		return

	var old_size := story_node.size

	if new_size == old_size:
		return

	history.record_property(
		'Change Node Size',
		story_node,
		&'size',
		new_size,
		old_size,
		story_node.emit_changed,
	)


## Takes `child` out of the tree immediately but frees it once the current call
## stack unwinds. Use instead of free(), which fails when called from one of the
## child's own signals (for example a button that rebuilds its row).
static func discard(child: Node) -> void:
	var parent: Node = child.get_parent()

	if parent != null:
		parent.remove_child(child)

	child.queue_free()


func _on_story_node_changed() -> void:
	if story_node == null:
		return

	if size != story_node.size:
		set_deferred("size", story_node.size)

	# Keeps the graph in step with undo/redo of moves.
	if position_offset != story_node.position:
		position_offset = story_node.position
