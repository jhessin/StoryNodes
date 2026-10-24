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
	if _character_library != null:
		if _character_library.changed.is_connected(_save):
			_character_library.changed.disconnect(_save)

	_character_library = data

	if not _character_library.changed.is_connected(_save):
		_character_library.changed.connect(_save)
	_refresh()


func _update_item_list_size() -> void:
	character_list.custom_minimum_size.y = character_list.item_count * ITEM_HEIGHT


func _on_color_changed(new_color: Color) -> void:
	if selected_character == null:
		return

	var old_color := selected_character.color
	_character_library.history.record_property(
		'Character Color Changed',
		selected_character,
		&'color',
		new_color,
		old_color,
		_character_library.emit_changed,
	)


func _on_image_changed(resource: Resource) -> void:
	if selected_character == null:
		return

	var old_image := selected_character.image
	var new_image := resource as Texture2D
	_character_library.history.record(
		'Character Image Changed',
		_image_change.bind(new_image),
		_image_change.bind(old_image),
	)


func _image_change(image: Texture2D) -> void:
	selected_character.image = image
	image_edit.edited_resource = image
	_character_library.emit_changed()


func _on_delete_character_pressed() -> void:
	if selected_character == null:
		return

	if _character_library == null:
		return

	_character_library.history.record(
		'Delete Character',
		_delete_character.bind(selected_character.id),
		_add_character.bind(selected_character.duplicate()),
	)


func _delete_character(character_id: StringName) -> void:
	_character_library.remove_character(character_id)
	_refresh()
	_select_character()
	selected_character = null


func _add_character(character: StoryCharacter) -> void:
	_character_library.add_character(character)
	_refresh()
	_select_character(character)
	selected_character = character


func _on_name_changed(new_name: String) -> void:
	if selected_character == null:
		return

	var selected_items := character_list.get_selected_items()
	if selected_items.is_empty():
		return

	var old_name := selected_character.name
	_character_library.history.record(
		'Rename Character',
		_name_change.bind(selected_character.id, new_name),
		_name_change.bind(selected_character.id, old_name),
	)


func _name_change(id: StringName, name: String) -> void:
	var character := _character_library.get_character(id)

	character.name = name
	name_edit.text = name
	_character_library.emit_changed()


func _on_character_selected(index: int) -> void:
	var new_character := character_list.get_item_metadata(index) as StoryCharacter
	if new_character.id not in _character_library.character_ids:
		push_error(
			'Invalid character - there is no character %s in the character library'
			% new_character.id
		)
	var old_character := selected_character

	_character_library.history.record(
		'Select Character',
		_select_character.bind(new_character),
		_select_character.bind(old_character),
	)


func _select_character(character: StoryCharacter = null) -> void:
	selected_character = character

	if character == null:
		character_list.deselect_all()
		name_edit.text = ''
		id_edit.text = ''
		image_edit.edited_resource = null
		color_edit.color = Color.WHITE

		name_edit.editable = false
		image_edit.editable = false
		color_edit.disabled = true

		return

	var index := _find_index_for_character(character)

	if index == -1:
		push_error('Invalid character selected: %s' % character.id)
		return

	character_list.select(index)
	name_edit.text = character.name
	id_edit.text = character.id
	image_edit.edited_resource = character.image
	color_edit.color = character.color

	name_edit.editable = true
	image_edit.editable = true
	color_edit.disabled = false


func _on_new_character_submitted(text: String) -> void:
	if _character_library == null:
		return

	if new_character_name.text.is_empty():
		push_warning('New characters need a name')
		return

	var character := StoryCharacter.new(_character_library.get_unique_id(new_character_name.text))
	character.name = new_character_name.text

	_character_library.add_character(character)

	new_character_name.text = ''

	_refresh()

	var index := _find_index_for_character(character)

	if index == -1:
		push_error('New character "%s" not found in the character list' % character.id)
		return

	character_list.select(index)
	_on_character_selected(index)
	new_character_name.grab_focus()
	new_character_name.select_all()


func _find_index_for_character(character: StoryCharacter) -> int:
	for i: int in range(character_list.item_count):
		var character_at_index := character_list.get_item_metadata(i) as StoryCharacter
		if character.id == character_at_index.id:
			return i

	return -1


func _on_new_character_pressed() -> void:
	_on_new_character_submitted(new_character_name.text)


func _refresh() -> void:
	character_list.clear()

	if _character_library == null:
		return

	for character: StoryCharacter in _character_library.character_list:
		var index := character_list.item_count
		character_list.add_item(character.name)
		character_list.set_item_metadata(index, character)

	_update_item_list_size()


func _save() -> void:
	if _character_library == null:
		return

	var error = ResourceSaver.save(_character_library)

	if error != OK:
		push_error('Error saving character library: ', error_string(error))
