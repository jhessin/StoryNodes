@tool
class_name ChoiceGraphNode
extends StoryGraphNode

var choice_node: ChoiceNode:
	get:
		return story_node as ChoiceNode

@onready var new_choice_field: LineEdit = %NewChoiceField


func _ready() -> void:
	new_choice_field.text_submitted.connect(_on_add_choice)
	_refresh_choices()


func set_story_node(node: StoryNode) -> void:
	if not node is ChoiceNode:
		push_error('ChoiceGraphNode requires a ChoiceNode')
		return

	super.set_story_node(node)
	_refresh_choices()


func _refresh_choices() -> void:
	if not is_node_ready():
		return

	for child: Node in get_children():
		if child != new_choice_field:
			child.free()

	if choice_node == null:
		return

	for index: int in range(choice_node.choices.size()):
		var choice: String = choice_node.choices[index]

		var editor := LineEdit.new()
		editor.text = choice
		editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		editor.text_changed.connect(_on_choice_changed.bind(index))

		var new_choice_index: int = get_children().find(new_choice_field)
		add_child(editor)
		move_child(editor, new_choice_index)

		var slot_index: int = get_children().find(editor)
		set_slot_enabled_right(slot_index, true)
		set_slot_type_right(slot_index, 0)


func _on_choice_changed(value: String, index: int) -> void:
	if choice_node == null:
		return

	if index < 0 or index >= choice_node.choices.size():
		return

	if value.is_empty():
		_delete_choice(index)
		return

	choice_node.choices[index] = value
	choice_node.emit_changed()

	if story_data != null:
		story_data.mark_changed()


func _on_add_choice(new_text: String) -> void:
	if choice_node == null:
		return

	choice_node.choices.append(new_text)
	choice_node.emit_changed()

	if story_data != null:
		story_data.mark_changed()

	new_choice_field.text = ''

	_refresh_choices()


func _delete_choice(index: int) -> void:
	if choice_node == null:
		return

	if index < 0 or index >= choice_node.choices.size():
		return

	choice_node.choices.remove_at(index)
	choice_node.emit_changed()

	if story_data != null:
		story_data.mark_changed()

	call_deferred('_refresh_choices')
	new_choice_field.grab_focus()
