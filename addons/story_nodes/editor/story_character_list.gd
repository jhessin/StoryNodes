@tool
class_name StoryCharacterList
extends ItemList

signal character_dropped(character: StoryCharacter)

var drop_enabled: bool = false


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not drop_enabled:
		return false

	if not data is Dictionary:
		return false

	if data.get('type', '') != 'story_character':
		return false

	return data.get('character') is StoryCharacter


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return

	var character := data.get('character') as StoryCharacter

	if character == null:
		return

	character_dropped.emit(character)


func _get_drag_data(at_position: Vector2) -> Variant:
	var index := get_item_at_position(at_position, true)

	if index < 0:
		return null

	var character := get_item_metadata(index) as StoryCharacter

	if character == null:
		return null

	var preview := Label.new()
	preview.text = character.name
	preview.add_theme_constant_override('outline_size', 4)
	preview.add_theme_color_override('font_outline_color', Color.BLACK)

	set_drag_preview(preview)

	return { 'type': 'story_character', 'character': character }
