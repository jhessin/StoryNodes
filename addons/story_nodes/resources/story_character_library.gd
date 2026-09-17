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
@export_storage
var _characters: Dictionary[StringName, StoryCharacter] = { }


func add_character(character: StoryCharacter) -> void:
	if character == null or character.id.is_empty():
		push_error('Invalid character being added to the library')
		return

	if _characters.has(character.id):
		push_error('Character: "%s" already exists.' % character.id)
		return

	_characters[character.id] = character
	emit_changed()


func remove_character(id: StringName) -> void:
	if not _characters.has(id):
		push_error('Cannot delete character that doesn\'t exist: "%s"' % id)
		return

	_characters.erase(id)
	emit_changed()


func get_character(id: StringName) -> StoryCharacter:
	return _characters.get(id, null)


func has_character(id: StringName) -> bool:
	return _characters.has(id)


func clear() -> void:
	_characters.clear()
	emit_changed()


func update_id(old_id: StringName, new_id: StringName) -> StringName:
	if not has_character(old_id):
		push_error('character is not in database: %s' % old_id)
		return &''

	var character := get_character(old_id)
	character.id = _get_unique_id(new_id)
	remove_character(old_id)
	add_character(character)
	return character.id


func _get_unique_id(base_name: String = 'bob') -> StringName:
	var index := 0
	base_name = base_name.to_lower().replace(' ', '_')

	var result = base_name

	while has_character(result):
		result = base_name.to_lower() + str(index)
		index += 1

	return result as StringName
