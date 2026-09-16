@tool
class_name StoryCharacterLibrary
extends Resource

@export var _characters: Array[StoryCharacter] = []

var character_list: Array[StoryCharacter]:
	get:
		return _characters

var character_count: int:
	get:
		return _characters.size()


func add_character(character: StoryCharacter) -> void:
	if character == null:
		return

	if _characters.has(character):
		return

	_characters.append(character)
	emit_changed()


func remove_character(character: StoryCharacter) -> void:
	if character == null:
		return

	if not _characters.has(character):
		return

	_characters.erase(character)
	emit_changed()


func has_character(character: StoryCharacter) -> bool:
	return _characters.has(character)


func clear() -> void:
	_characters.clear()
	emit_changed()
