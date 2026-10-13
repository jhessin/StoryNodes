@tool
class_name StoryCharacter
extends Resource

@export var name: String:
	get:
		return _name
	set(new_value):
		var old_value = _name
		if old_value == new_value:
			return
		if _undo_redo == null:
			_name = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set name')

		_undo_redo.add_do_property(self, '_name', new_value)
		_undo_redo.add_undo_property(self, '_name', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()
@export var image: Texture2D:
	get:
		return _image
	set(new_value):
		var old_value = _image
		if old_value == new_value:
			return
		if _undo_redo == null:
			_image = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set image')

		_undo_redo.add_do_property(self, '_image', new_value)
		_undo_redo.add_undo_property(self, '_image', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()
@export var color: Color:
	get:
		return _color
	set(new_value):
		var old_value = _color
		if old_value == new_value:
			return
		if _undo_redo == null:
			_color = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set color')

		_undo_redo.add_do_property(self, '_color', new_value)
		_undo_redo.add_undo_property(self, '_color', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

@export var id: StringName:
	get:
		return _id

var _name: String = ''
var _image: Texture2D
var _color: Color = Color.WHITE
var _undo_redo: UndoRedo

var _id: StringName = &''


func _init(character_name: String = '') -> void:
	_id = character_name.replace(' ', '_').to_lower()
	name = character_name


func set_undo_redo(undo_redo: UndoRedo) -> void:
	if undo_redo == null:
		push_error('Every story node needs access to the story\'s UndoRedo!')
		return

	_undo_redo = undo_redo
