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


func set_story_data(data: StoryData) -> void:
	super.set_story_data(data)

	if story_data != null:
		story_data.changed.connect(_refresh_character_picker)


func set_story_node(node: StoryNode) -> void:
	if not node is DialogueNode:
		push_error('DialogueGraphNode requires a DialogueNode.')
		return

	super.set_story_node(node)

	title = 'Dialogue'
	dialogue_edit.text = dialogue_node.dialogue
	_refresh_character_picker()


func _on_character_selected(index: int) -> void:
	if story_node == null:
		return

	if not story_node is DialogueNode:
		return

	var dialogue_node := story_node as DialogueNode
	var character := character_picker.get_item_metadata(index) as StoryCharacter

	dialogue_node.character = character.id
	dialogue_node.emit_changed()

	if story_data != null:
		story_data.mark_changed()


func _refresh_character_picker() -> void:
	if not is_node_ready():
		return

	character_picker.clear()

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

	var dialogue_node := story_node as DialogueNode
	dialogue_node.dialogue = dialogue_edit.text

	if story_data != null:
		story_data.mark_changed()
