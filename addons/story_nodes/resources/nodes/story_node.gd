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
		if _undo_redo == null:
			_position = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set position')

		_undo_redo.add_do_property(self, '_position', new_value)
		_undo_redo.add_undo_property(self, '_position', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

@export_storage
var size: Vector2:
	get:
		return _size
	set(new_value):
		var old_value = _size
		if old_value == new_value:
			return
		if _undo_redo == null:
			_size = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set size')

		_undo_redo.add_do_property(self, '_size', new_value)
		_undo_redo.add_undo_property(self, '_size', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

var _size: Vector2 = Vector2.ZERO
var _position: Vector2 = Vector2.ZERO

var _undo_redo: UndoRedo


func set_undo_redo(undo_redo: UndoRedo) -> void:
	if undo_redo == null:
		push_error('Every story node needs access to the story\'s UndoRedo!')
		return

	_undo_redo = undo_redo
