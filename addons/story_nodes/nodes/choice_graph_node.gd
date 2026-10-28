@tool
class_name ChoiceGraphNode
extends StoryGraphNode

var choice_node: ChoiceNode:
	get:
		return story_node as ChoiceNode

## Row to focus after the next rebuild (set when a choice is deleted).
var _pending_focus_index: int = -1

@onready var new_choice_field: LineEdit = %NewChoiceField


func _ready() -> void:
	new_choice_field.text_submitted.connect(_on_add_choice)
	_sync_choices()
	super._ready()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is int


func _drop_data(at_position: Vector2, data: Variant) -> void:
	pass


func set_story_node(node: StoryNode) -> void:
	if not node is ChoiceNode:
		push_error('ChoiceGraphNode requires a ChoiceNode')
		return

	if choice_node != null and choice_node.changed.is_connected(_sync_choices):
		choice_node.changed.disconnect(_sync_choices)

	super.set_story_node(node)

	if not choice_node.changed.is_connected(_sync_choices):
		choice_node.changed.connect(_sync_choices)

	_sync_choices()


func _drop_from(target_position: Vector2, data: Variant, source_control: Control) -> void:
	if not data is int:
		return

	if choice_node == null:
		return

	var source_index: int = data
	var target_index: int = source_control.get_meta('choice_index')
	var count: int = choice_node.choices.size()

	if source_index == target_index:
		return

	if source_index < 0 or source_index >= count:
		return

	if target_index < 0 or target_index >= count:
		return

	history.record(
		'Move Choice',
		_move_choice.bind(source_index, target_index),
		_move_choice.bind(target_index, source_index),
	)


func _move_choice(source_index: int, target_index: int) -> void:
	# The node's own change signal updates the rows; StoryData's links_changed
	# signal redraws the connections.
	choice_node.move_choice(source_index, target_index)
	story_data.move_link_port(choice_node.instance_id, source_index, target_index)


## Brings the rows in line with the node. Text-only changes update the rows in
## place (so typing keeps focus); added or removed choices rebuild them.
func _sync_choices() -> void:
	if not is_node_ready() or choice_node == null:
		return

	var choices: Array[String] = choice_node.choices
	var rows: Array[HBoxContainer] = _get_rows()

	if rows.size() != choices.size():
		_rebuild_rows(choices, rows)
		return

	for index: int in choices.size():
		var editor: LineEdit = rows[index].get_child(1) as LineEdit

		if editor.text != choices[index]:
			_set_editor_text(editor, choices[index])


func _get_rows() -> Array[HBoxContainer]:
	var rows: Array[HBoxContainer] = []

	for child: Node in get_children():
		if child is HBoxContainer and child.has_meta('choice_index'):
			rows.append(child as HBoxContainer)

	return rows


func _rebuild_rows(choices: Array[String], old_rows: Array[HBoxContainer]) -> void:
	for row: HBoxContainer in old_rows:
		discard(row)

	for index: int in choices.size():
		_add_row(choices[index], index)

	# The "new choice" row has no output port.
	var new_choice_index: int = get_children().find(new_choice_field)

	if new_choice_index >= 0:
		set_slot_enabled_right(new_choice_index, false)

	ports_changed.emit()

	if _pending_focus_index >= 0:
		_focus_index(_pending_focus_index)
		_pending_focus_index = -1


func _add_row(choice: String, index: int) -> void:
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


func _set_editor_text(editor: LineEdit, text: String) -> void:
	var column: int = editor.caret_column
	editor.text = text
	editor.caret_column = mini(column, text.length())


func _on_choice_changed(new_choice: String, index: int) -> void:
	if choice_node == null:
		return

	if index < 0 or index >= choice_node.choices.size():
		return

	if new_choice.is_empty():
		_pending_focus_index = maxi(index - 1, 0)
		story_data.remove_choice(choice_node.instance_id, index)
		return

	choice_node.set_choice(index, new_choice)


func _on_add_choice(new_text: String) -> void:
	if choice_node == null:
		return

	if new_text.is_empty():
		push_warning('Cannot create empty choices.')
		return

	new_choice_field.text = ''
	choice_node.add_choice(new_text)


func _focus_index(index: int) -> void:
	var rows: Array[HBoxContainer] = _get_rows()

	if index < 0 or index >= rows.size():
		_focus_new_choice_field()
		return

	var editor: LineEdit = rows[index].get_child(1) as LineEdit
	editor.grab_focus()
	editor.caret_column = editor.text.length()


func _focus_new_choice_field() -> void:
	new_choice_field.grab_focus()
	new_choice_field.caret_column = new_choice_field.text.length()
