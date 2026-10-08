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
	super._ready()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is int


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is int:
		return

	var source_index: int = data


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

	undo_redo.create_action('Move Choice')

	undo_redo.add_do_method(_move_choice.bind(source_index, target_index))
	undo_redo.add_undo_method(_move_choice.bind(target_index, source_index))

	undo_redo.commit_action()


func _move_choice(source_index: int, target_index: int) -> void:
	choice_node.move_choice(source_index, target_index)
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


func _on_choice_changed(new_choice: String, index: int) -> void:
	if choice_node == null:
		return

	if index < 0 or index >= choice_node.choices.size():
		return

	var old_choice := choice_node.choices[index]

	if new_choice.is_empty():
		undo_redo.create_action('Delete Choice')

		var links: Array[StoryLink] = story_data.get_links_from_port(choice_node.instance_id, index)

		undo_redo.add_do_method(_delete_choice.bind(index))
		undo_redo.add_do_method(_focus_index.bind(index - 1 if index > 0 else 0))

		undo_redo.add_undo_method(_add_choice.bind(index, old_choice))
		undo_redo.add_undo_method(story_data.unshift_link_ports.bind(choice_node.instance_id, index))
		for link: StoryLink in links:
			undo_redo.add_undo_method(story_data.add_link.bind(
					link.from,
					link.to,
					link.from_port,
					link.to_port,
				))
		undo_redo.add_undo_method(_focus_index.bind(index - 1 if index > 0 else 0))
		undo_redo.add_undo_method(_refresh_choices_and_notify)

		undo_redo.call_deferred('commit_action')
		return

	undo_redo.create_action('Update Choice')

	undo_redo.add_do_method(_update_choice.bind(index, new_choice))
	undo_redo.add_undo_method(_update_choice.bind(index, old_choice))

	undo_redo.commit_action()


func _update_choice(index: int, new_value: String) -> void:
	if choice_node == null or story_data == null:
		return
	var row: HBoxContainer = get_child(index) as HBoxContainer
	var editor: LineEdit = row.get_child(1) as LineEdit

	if editor == null:
		_focus_new_choice_field()
		return

	var focused: bool = editor.has_focus()
	var col: int

	if focused:
		col = editor.get_caret_column()

	choice_node.choices[index] = new_value
	editor.text = new_value

	if focused:
		editor.set_caret_column(col)

	choice_node.emit_changed()
	story_data.emit_changed()


func _focus_index(index: int) -> void:
	var row: HBoxContainer = get_child(index) as HBoxContainer

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

	var index := choice_node.choices.size()

	undo_redo.create_action('Add a choice')

	undo_redo.add_do_method(_add_choice.bind(index, new_text))
	undo_redo.add_undo_method(_delete_choice.bind(index))

	undo_redo.commit_action()


func _add_choice(index: int, new_text: String) -> void:
	if choice_node == null or story_data == null:
		return

	choice_node.choices.insert(index, new_text)
	choice_node.emit_changed()
	story_data.emit_changed()

	new_choice_field.text = ''
	_refresh_choices()


func _delete_choice(index: int) -> void:
	if choice_node == null or story_data == null:
		return

	if index < 0 or index >= choice_node.choices.size():
		return

	story_data.remove_link_from_port(choice_node.instance_id, index)
	story_data.shift_link_ports(choice_node.instance_id, index)

	choice_node.choices.remove_at(index)
	choice_node.emit_changed()

	story_data.emit_changed()

	_refresh_choices_and_notify()


func _refresh_choices_and_notify() -> void:
	_refresh_choices()
	ports_changed.emit()
