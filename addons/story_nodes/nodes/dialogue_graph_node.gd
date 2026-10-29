@tool
class_name DialogueGraphNode
extends StoryGraphNode

var dialogue_node: DialogueNode:
	get:
		return story_node as DialogueNode

@onready var character_picker: OptionButton = %CharacterPicker
@onready var dialogue_edit: TextEdit = %Dialogue


func _ready() -> void:
	character_picker.item_selected.connect(_on_character_selected)
	dialogue_edit.text_changed.connect(_on_dialogue_changed)
	super._ready()


func set_story_data(data: StoryData) -> void:
	super.set_story_data(data)

	if story_data != null:
		story_data.changed.connect(_refresh_character_picker)


func set_story_node(node: StoryNode) -> void:
	if not node is DialogueNode:
		push_error('DialogueGraphNode requires a DialogueNode.')
		return

	super.set_story_node(node)

	dialogue_edit.text = dialogue_node.dialogue
	_refresh_character_picker()


func _on_character_selected(index: int) -> void:
	if story_node == null:
		return

	if not story_node is DialogueNode:
		return

	if story_data == null:
		push_error('StoryData must be assigned to DialogueGraphNode')

	var new_character: StoryCharacter
	if index == 0:
		new_character = null
	else:
		new_character = character_picker.get_item_metadata(index) as StoryCharacter
	var old_character := dialogue_node.character

	history.record(
		'Select Character',
		_select_character.bind(new_character),
		_select_character.bind(old_character),
	)


func _select_character(character: StoryCharacter = null) -> void:
	if character == null:
		character_picker.select(0)
		dialogue_node.character = &''
		dialogue_node.emit_changed()
		return

	character_picker.select(_find_character_index(character))

	dialogue_node.character = character.id
	dialogue_node.emit_changed()

	if story_data != null:
		story_data.emit_changed()


func _find_character_index(character: StoryCharacter) -> int:
	for i: int in range(1, character_picker.item_count):
		if i == 0:
			continue
		var this_char := character_picker.get_item_metadata(i) as StoryCharacter
		if this_char.id == character.id:
			return i
	return -1


func _refresh_character_picker() -> void:
	if not is_node_ready():
		return

	character_picker.clear()

	character_picker.add_item('None')
	character_picker.set_item_metadata(0, null)

	if story_data == null:
		push_error('DialogueGraphNode: story_data is null.')
		return

	var dialogue_node := story_node as DialogueNode

	for character: StoryCharacter in story_data.cast:
		character_picker.add_item(character.name)
		var index: int = character_picker.item_count - 1

		character_picker.set_item_metadata(index, character)

		if dialogue_node != null and dialogue_node.character == character.id:
			character_picker.select(index)


func _on_dialogue_changed() -> void:
	if story_node == null:
		return

	if not story_node is DialogueNode:
		return

	var old_text := dialogue_node.dialogue
	var new_text := dialogue_edit.text

	history.record(
		'Update Dialogue',
		_update_dialogue.bind(new_text),
		_update_dialogue.bind(old_text),
	)


func _update_dialogue(text: String) -> void:
	dialogue_node.dialogue = text
	var focused: bool = dialogue_edit.has_focus()
	var line: int
	var col: int

	if focused:
		line = dialogue_edit.get_caret_line()
		col = dialogue_edit.get_caret_column()

	dialogue_edit.text = text
	if focused:
		dialogue_edit.set_caret_column(col)
		dialogue_edit.set_caret_line(line)

	story_data.emit_changed()
