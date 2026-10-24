@tool
class_name StoryCharacterLibrary
extends Resource

@export_storage var _characters: Dictionary[StringName, StoryCharacter] = { }

var character_list: Array[StoryCharacter]:
	get:
		return _characters.values()

var character_ids: Array[StringName]:
	get:
		return _characters.keys()

var character_count: int:
	get:
		return _characters.size()
var history: StoryHistory:
	get:
		return _history

var has_undo: bool:
	get:
		return _history.undo_redo.has_undo()

var has_redo: bool:
	get:
		return _history.undo_redo.has_redo()
var _history: StoryHistory = StoryHistory.new()


func undo() -> void:
	_history.undo_redo.undo()


func redo() -> void:
	_history.undo_redo.redo()


func add_character(character: StoryCharacter) -> void:
	if character == null:
		push_error('Cannot add a null character.')
		return

	if character.id.is_empty():
		push_error('Cannot add a character with an empty ID.')
		return

	if _characters.has(character.id):
		push_error('Character "%s" already exists.' % character.id)
		return

	character.set_history(_history)

	_history.record(
		'Add Character',
		_add_character.bind(character),
		_remove_character.bind(character.id),
	)


func remove_character(id: StringName) -> void:
	if not _characters.has(id):
		push_error('Cannot delete character that doesn\'t exist: "%s"' % id)
		return

	var character: StoryCharacter = _characters[id]

	_history.record('Remove character', _remove_character.bind(id), _add_character.bind(character))


func get_character(id: StringName) -> StoryCharacter:
	return _characters.get(id, null)


func has_character(id: StringName) -> bool:
	return _characters.has(id)


func get_unique_id(base_name: String = 'bob') -> StringName:
	var index := 0
	base_name = base_name.to_lower().replace(' ', '_')

	var result = base_name

	while has_character(result):
		result = base_name.to_lower() + str(index)
		index += 1

	return result as StringName


func _add_character(character: StoryCharacter) -> void:
	_characters[character.id] = character
	emit_changed()


func _remove_character(id: StringName) -> void:
	_characters.erase(id)
	emit_changed()
