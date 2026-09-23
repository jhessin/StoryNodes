@tool
class_name ChoiceGraphNode
extends StoryGraphNode

var choice_node: ChoiceNode:
	get:
		return story_node as ChoiceNode

var _deleted_index: int = 0

@onready var new_choice_field: LineEdit = %NewChoiceField


func _ready() -> void:
	new_choice_field.text_submitted.connect(_on_add_choice)
	_refresh_choices()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is int


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is int:
		return

	var source_index: int = data

	print('Dragged choice: ', source_index)


func set_story_node(node: StoryNode) -> void:
	if not node is ChoiceNode:
		push_error('ChoiceGraphNode requires a ChoiceNode')
		return

	super.set_story_node(node)
	_refresh_choices()


func _drop_from(target_position: Vector2, data: Variant, source_control: Control) -> void:
	if not data is int:
		return

	if choice_node == null:
		return

	var source_index: int = data
	var target_index: int = source_control.get_meta('choice_index')

	if source_index == target_index:
		return

	if source_index < 0 or source_index >= choice_node.choices.size():
		return

	if target_index < 0 or target_index >= choice_node.choices.size():
		return

	choice_node.move_choice(source_index, target_index)

	if story_data != null:
		story_data.move_link_port(choice_node.instance_id, source_index, target_index)

	_refresh_choices()
	ports_changed.emit()


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

		# Create a draggable handle
		var handle := StoryDragHandle.new()
		handle.drag_data = index

		var editor := LineEdit.new()
		editor.text = choice
		editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		editor.text_changed.connect(_on_choice_changed.bind(index))

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.set_meta('choice_index', index)

		row.add_child(handle)
		row.add_child(editor)

		handle.set_drag_forwarding(Callable(), _can_drop_data, _drop_from.bind(row))
		editor.set_drag_forwarding(Callable(), _can_drop_data, _drop_from.bind(row))

		var new_choice_index: int = get_children().find(new_choice_field)
		add_child(row)
		move_child(row, new_choice_index)

		var slot_index: int = get_children().find(row)
		set_slot_enabled_right(slot_index, true)
		set_slot_type_right(slot_index, 0)

	var new_choice_index: int = get_children().find(new_choice_field)

	if new_choice_index >= 0:
		set_slot_enabled_right(new_choice_index, false)


func _on_choice_changed(value: String, index: int) -> void:
	if choice_node == null:
		return

	if index < 0 or index >= choice_node.choices.size():
		return

	if value.is_empty():
		_delete_choice(index)
		_deleted_index = index - 1 if index > 0 else 0
		call_deferred('_focus_index')
		return

	choice_node.choices[index] = value
	choice_node.emit_changed()

	if story_data != null:
		story_data.mark_changed()


func _focus_index() -> void:
	var row: HBoxContainer = get_child(_deleted_index) as HBoxContainer

	if row == null:
		_focus_new_choice_field()
		return

	var editor: LineEdit = row.get_child(1) as LineEdit

	if editor == null:
		_focus_new_choice_field()
		return

	editor.grab_focus()
	editor.caret_column = editor.text.length()


func _focus_new_choice_field() -> void:
	new_choice_field.grab_focus()
	new_choice_field.caret_column = new_choice_field.text.length()


func _on_add_choice(new_text: String) -> void:
	if choice_node == null:
		return

	if new_text.is_empty():
		push_warning('Cannot create empty choices.')
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

	if story_data != null:
		story_data.remove_link_from_port(choice_node.instance_id, index)
		story_data.shift_link_ports(choice_node.instance_id, index)

	choice_node.choices.remove_at(index)
	choice_node.emit_changed()

	if story_data != null:
		story_data.mark_changed()

	call_deferred('_refresh_choices_and_notify')


func _refresh_choices_and_notify() -> void:
	_refresh_choices()
	ports_changed.emit()
