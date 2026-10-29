@tool
class_name StoryNode
extends Resource

@export var node_id: StringName = &'StoryNode'
@export var instance_id: StringName = &""

@export var graph_scene: PackedScene
@export var runtime_scene: PackedScene

@export var display_name: String = ""

@export_multiline var description: String = ""

@export_storage
var position: Vector2:
	get:
		return _position
	set(new_value):
		var old_value = _position
		if old_value == new_value:
			return
		if _history == null:
			_position = new_value
			emit_changed()
			return

		_history.record_property(
			'Set Position',
			self,
			&'_position',
			new_value,
			_position,
			emit_changed,
		)

@export_storage
var size: Vector2:
	get:
		return _size
	set(new_value):
		var old_value = _size
		if old_value == new_value:
			return
		if _history == null:
			_size = new_value
			emit_changed()
			return

		_history.record_property('Set Size', self, &'_size', new_value, _size, emit_changed)

var _size: Vector2 = Vector2.ZERO
var _position: Vector2 = Vector2.ZERO

var _history: StoryHistory


## Runtime hook for custom node types (built-in nodes are handled by
## StoryExecution). Return the output port to follow, StoryExecution.WAIT to
## pause until StoryExecution.advance() is called, or StoryExecution.END.
func execute(_execution: StoryExecution) -> int:
	return 0


func set_history(history: StoryHistory) -> void:
	if history == null:
		push_error('Every story node needs access to the story\'s history!')
		return

	_history = history
