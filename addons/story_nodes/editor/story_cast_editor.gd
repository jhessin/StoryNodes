@tool
class_name StoryCastEditor
extends HSplitContainer

const ITEM_HEIGHT: float = 32.0

var _story_data: StoryData
var _character_library: StoryCharacterLibrary

@onready var character_library_list: StoryCharacterList = %CharacterLibraryList
@onready var cast_list: StoryCharacterList = %CastList


func _ready() -> void:
	character_library_list.drop_enabled = true
	cast_list.drop_enabled = true

	character_library_list.character_dropped.connect(_on_character_dropped_to_library)

	cast_list.character_dropped.connect(_on_character_dropped_to_cast)

	_refresh()


func set_story_data(data: StoryData) -> void:
	if _character_library != null and _character_library.changed.is_connected(_refresh):
		_character_library.changed.disconnect(_refresh)

	_story_data = data

	if _story_data == null:
		_character_library = null
	else:
		_character_library = _story_data.character_library

	if _character_library != null:
		if not _character_library.changed.is_connected(_refresh):
			_character_library.changed.connect(_refresh)

	_refresh()


func _on_character_dropped_to_cast(character: StoryCharacter) -> void:
	if _story_data == null:
		return

	_story_data.add_to_cast(character)
	_refresh()


func _on_character_dropped_to_library(character: StoryCharacter) -> void:
	if _story_data == null:
		return

	_story_data.remove_from_cast(character)
	_refresh()


func _refresh() -> void:
	character_library_list.clear()
	cast_list.clear()

	if _story_data == null:
		return

	if _character_library == null:
		return

	for character: StoryCharacter in _character_library.character_list:
		if _story_data.is_in_cast(character):
			continue

		var index := character_library_list.add_item(character.name)
		character_library_list.set_item_metadata(index, character)

	for character: StoryCharacter in _story_data.cast:
		var index := cast_list.add_item(character.name)
		cast_list.set_item_metadata(index, character)

	_update_item_list_sizes()


func _update_item_list_sizes() -> void:
	character_library_list.custom_minimum_size.y = (character_library_list.item_count * ITEM_HEIGHT)

	cast_list.custom_minimum_size.y = (cast_list.item_count * ITEM_HEIGHT)
