@tool
class_name StoryCharactersEditor
extends HSplitContainer

const ITEM_HEIGHT: float = 32.0

var selected_character: StoryCharacter
var _character_library: StoryCharacterLibrary

@onready var character_list: ItemList = %CharacterList

# Fields
@onready var new_character_name: LineEdit = %NewCharacterName
@onready var id_edit: LineEdit = %IdEdit
@onready var name_edit: LineEdit = %NameEdit
@onready var image_edit: EditorResourcePicker = %ImageEdit
@onready var color_edit: ColorPickerButton = %ColorEdit

# Buttons
@onready var delete_button: Button = %DeleteButton
@onready var new_character_button: Button = %NewCharacterButton


func _ready() -> void:
	new_character_button.pressed.connect(_on_new_character_pressed)
	new_character_name.text_submitted.connect(_on_new_character_submitted)
	character_list.item_selected.connect(_on_character_selected)
	name_edit.text_changed.connect(_on_name_changed)
	delete_button.pressed.connect(_on_delete_character_pressed)

	image_edit.base_type = 'Texture2D'
	image_edit.resource_changed.connect(_on_image_changed)

	color_edit.color_changed.connect(_on_color_changed)


func set_character_library(data: StoryCharacterLibrary) -> void:
	_character_library = data
	_refresh()


func _update_item_list_size() -> void:
	character_list.custom_minimum_size.y = character_list.item_count * ITEM_HEIGHT


func _on_color_changed(new_color: Color) -> void:
	if selected_character == null:
		return

	selected_character.color = new_color
	_character_library.emit_changed()


func _on_image_changed(resource: Resource) -> void:
	if selected_character == null:
		return

	selected_character.image = resource as Texture2D
	_character_library.emit_changed()


func _on_delete_character_pressed() -> void:
	if selected_character == null:
		return

	if _character_library == null:
		return

	_character_library.remove_character(selected_character.id)

	selected_character = null

	name_edit.clear()
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

	_character_library.emit_changed()


func _on_character_selected(index: int) -> void:
	var character := _character_library.character_list[index]

	selected_character = character

	name_edit.text = character.name
	id_edit.text = character.id
	image_edit.edited_resource = character.image
	color_edit.color = character.color


func _on_new_character_submitted(text: String) -> void:
	if _character_library == null:
		return

	if new_character_name.text.is_empty():
		push_warning('New characters need a name')
		return

	var character := StoryCharacter.new()
	character.id = _character_library.get_unique_id(new_character_name.text)
	character.name = new_character_name.text

	_character_library.add_character(character)

	new_character_name.text = ''

	_refresh()

	var index := _character_library.character_list.find(character)

	if index == -1:
		return

	character_list.select(index)
	_on_character_selected(index)


func _on_new_character_pressed() -> void:
	_on_new_character_submitted(new_character_name.text)


func _refresh() -> void:
	character_list.clear()

	if _character_library == null:
		return

	for character: StoryCharacter in _character_library.character_list:
		character_list.add_item(character.name)

	_update_item_list_size()
