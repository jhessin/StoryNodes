@tool
class_name DialogueGraphNode
extends StoryGraphNode

@onready var character_picker: OptionButton = %CharacterPicker


func _ready() -> void:
	character_picker.item_selected.connect(_on_character_selected)


func set_story_data(data: StoryData) -> void:
	super.set_story_data(data)
	_refresh_character_picker()


func set_story_node(node: StoryNode) -> void:
	super.set_story_node(node)

	if node is DialogueNode:
		_refresh_character_picker()


func _on_character_selected(index: int) -> void:
	if story_node == null:
		return

	if not story_node is DialogueNode:
		return

	var dialogue_node := story_node as DialogueNode
	var character := character_picker.get_item_metadata(index) as StoryCharacter

	dialogue_node.character = character

	if story_data != null:
		story_data.mark_changed()


func _refresh_character_picker() -> void:
	if not is_node_ready():
		return

	character_picker.clear()

	if story_data == null:
		return

	var dialogue_node := story_node as DialogueNode

	for character: StoryCharacter in story_data.cast:
		character_picker.add_item(character.name)
		var index: int = character_picker.item_count - 1

		character_picker.set_item_metadata(index, character)

		if dialogue_node != null and dialogue_node.character == character:
			character_picker.select(index)
