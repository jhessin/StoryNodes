@tool
class_name StoryCharactersEditor
extends Control

var selected_character: StoryCharacter
var _story_data: StoryData

@onready var image_edit: EditorResourcePicker = %ImageEdit
@onready var color_edit: ColorPickerButton = %ColorEdit

@onready var character_list: ItemList = %CharacterList


func _ready() -> void:
	%NewCharacterButton.pressed.connect(_on_new_character_pressed)
	character_list.item_selected.connect(_on_character_selected)
	%NameEdit.text_changed.connect(_on_name_changed)
	%DeleteButton.pressed.connect(_on_delete_character_pressed)

	image_edit.base_type = 'Texture2D'
	image_edit.resource_changed.connect(_on_image_changed)

	color_edit.color_changed.connect(_on_color_changed)


func set_story_data(data: StoryData) -> void:
	_story_data = data
	_refresh()


func _on_color_changed(new_color: Color) -> void:
	if selected_character == null:
		return

	selected_character.color = new_color
	_story_data.mark_changed()


func _on_image_changed(resource: Resource) -> void:
	if selected_character == null:
		return

	selected_character.image = resource as Texture2D
	_story_data.mark_changed()


func _on_delete_character_pressed() -> void:
	if selected_character == null:
		return

	if _story_data == null:
		return

	_story_data.remove_character(selected_character)

	selected_character = null

	%NameEdit.clear()
	color_edit.color = Color.WHITE
	image_edit.edited_resource = null

	_refresh()


func _on_name_changed(new_name: String) -> void:
	if selected_character == null:
		return

	selected_character.name = new_name

	var selected_items := character_list.get_selected_items()

	if selected_items.is_empty():
		return

	character_list.set_item_text(selected_items[0], new_name)
	_story_data.mark_changed()


func _on_character_selected(index: int) -> void:
	var character := _story_data.character_list[index]

	selected_character = character

	%NameEdit.text = character.name
	image_edit.edited_resource = character.image
	color_edit.color = character.color


func _on_new_character_pressed() -> void:
	if _story_data == null:
		return

	var character := StoryCharacter.new('New Character')

	_story_data.add_character(character)

	_refresh()

	var index := _story_data.character_list.find(character)

	if index == -1:
		return

	character_list.select(index)
	_on_character_selected(index)


func _refresh() -> void:
	character_list.clear()

	if _story_data == null:
		return

	for character: StoryCharacter in _story_data.character_list:
		character_list.add_item(character.name)
