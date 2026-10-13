@tool
class_name StoryCharacterLibrary
extends Resource

var character_list: Array[StoryCharacter]:
	get:
		return _characters.values()

var character_ids: Array[StringName]:
	get:
		return _characters.keys()

var character_count: int:
	get:
		return _characters.size()

var undo_redo: UndoRedo = UndoRedo.new()

@export_storage
var _characters: Dictionary[StringName, StoryCharacter] = { }


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

	character.set_undo_redo(undo_redo)

	undo_redo.create_action('Add character')

	undo_redo.add_do_method(_add_character.bind(character))
	undo_redo.add_undo_method(_remove_character.bind(character.id))

	undo_redo.commit_action()


func remove_character(id: StringName) -> void:
	if not _characters.has(id):
		push_error('Cannot delete character that doesn\'t exist: "%s"' % id)
		return

	var character: StoryCharacter = _characters[id]

	undo_redo.create_action('Remove character')

	undo_redo.add_do_method(_remove_character.bind(id))
	undo_redo.add_undo_method(_add_character.bind(character))

	undo_redo.commit_action()


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
