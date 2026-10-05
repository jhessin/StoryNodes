@tool
class_name BranchGraphNode
extends StoryGraphNode

const CONDITION_ROW_SCENE: PackedScene = preload(
	'res://addons/story_nodes/nodes/condition_row.tscn'
)

var branch_node: BranchNode:
	get:
		return story_node as BranchNode

@onready var variable_picker: OptionButton = %VariablePicker
@onready var new_condition_button: Button = %NewConditionButton


func _ready() -> void:
	new_condition_button.pressed.connect(_on_new_condition_pressed)
	variable_picker.item_selected.connect(_on_variable_selected)

	super._ready()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is int


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is int:
		return

	var source_index: int = data


func set_story_node(node: StoryNode) -> void:
	if not node is BranchNode:
		push_error('BranchGraphNode requires a BranchNode.')
		return

	super.set_story_node(node)
	_refresh_variable_picker()
	_refresh_condition_rows()

	if is_visible_in_tree():
		var index := _find_index_for_variable(story_node.variable)
		variable_picker.select(index)
	else:
		if not visibility_changed.is_connected(_on_visibility_changed):
			visibility_changed.connect(_on_visibility_changed)

	if branch_node == null or branch_node.variable == null:
		new_condition_button.disabled = true
	else:
		new_condition_button.disabled = false


func set_story_data(data: StoryData) -> void:
	super.set_story_data(data)

	if story_data == null:
		return

	if story_data.variable_library == null:
		return

	story_data.variable_library.changed.connect(_refresh_variable_picker)
	_refresh_variable_picker()


func _on_visibility_changed():
	if is_visible_in_tree():
		var index := _find_index_for_variable(story_node.variable)
		variable_picker.select(index)
		if visibility_changed.is_connected(_on_visibility_changed):
			visibility_changed.disconnect(_on_visibility_changed)


func _on_new_condition_pressed() -> void:
	if branch_node == null:
		return

	if branch_node.variable == null:
		return

	if branch_node == null or branch_node.variable == null:
		return

	var condition: BranchCondition = BranchCondition.new()
	condition.initialize_for_variable(branch_node.variable)

	if story_data == null:
		return

	var undo_redo := story_data.undo_redo

	undo_redo.create_action('Add new condition')
	undo_redo.add_do_method(_add_condition.bind(condition))
	undo_redo.add_undo_method(_remove_condition.bind(condition))
	story_data.update_revision()
	undo_redo.commit_action(true)


func _add_condition(condition: BranchCondition, notify: bool = false) -> void:
	branch_node.conditions.append(condition)
	branch_node.emit_changed()
	story_data.emit_changed()
	if notify:
		call_deferred('_refresh_condition_rows_and_notify')
	else:
		_refresh_condition_rows()


func _remove_condition(condition: BranchCondition, notify: bool = false) -> void:
	branch_node.conditions.erase(condition)
	branch_node.emit_changed()
	story_data.emit_changed()
	if notify:
		call_deferred('_refresh_condition_rows_and_notify')
	else:
		_refresh_condition_rows()


func _on_variable_selected(index: int) -> void:
	if branch_node == null or story_data == null:
		return

	var undo_redo := story_data.undo_redo

	undo_redo.create_action('Select Variable')
	var previous_variable := branch_node.variable
	var previous_index := _find_index_for_variable(previous_variable)

	if index == 0:
		if previous_variable == null:
			undo_redo.abort_action()
			return

		undo_redo.add_do_property(branch_node, 'variable', null)
		undo_redo.add_do_method(branch_node.emit_changed)
		undo_redo.add_do_method(story_data.emit_changed)
		undo_redo.add_do_property(new_condition_button, 'disabled', true)
		undo_redo.add_do_method(variable_picker.select.bind(index))
		undo_redo.add_do_method(_refresh_condition_rows)

		undo_redo.add_undo_property(branch_node, 'variable', previous_variable)
		undo_redo.add_undo_method(branch_node.emit_changed)
		undo_redo.add_undo_method(story_data.emit_changed)
		undo_redo.add_undo_property(new_condition_button, 'disabled', false)
		undo_redo.add_undo_method(_refresh_condition_rows)
		undo_redo.add_undo_method(variable_picker.select.bind(previous_index))

		story_data.update_revision()

		undo_redo.commit_action()

		return

	undo_redo.add_do_property(new_condition_button, 'disabled', false)

	if story_data == null or story_data.variable_library == null:
		undo_redo.abort_action()
		return

	var variable_index: int = index - 1
	var variables: Array[StoryVariable] = story_data.variable_library.variable_list

	if variable_index < 0 or variable_index >= variables.size():
		undo_redo.abort_action()
		return

	var variable: StoryVariable = variables[variable_index]

	undo_redo.add_do_property(branch_node, 'variable', variable)
	undo_redo.add_do_method(branch_node.emit_changed)
	undo_redo.add_do_method(story_data.emit_changed)
	undo_redo.add_do_method(variable_picker.select.bind(index))
	undo_redo.add_do_method(_refresh_condition_rows)

	undo_redo.add_undo_property(branch_node, 'variable', previous_variable)
	undo_redo.add_undo_method(branch_node.emit_changed)
	undo_redo.add_undo_method(story_data.emit_changed)
	undo_redo.add_undo_property(new_condition_button, 'disabled', false)
	undo_redo.add_undo_method(variable_picker.select.bind(previous_index))
	undo_redo.add_undo_method(_refresh_condition_rows)

	story_data.update_revision()

	undo_redo.commit_action()


func _find_index_for_variable(variable: StoryVariable) -> int:
	if story_data == null or story_data.variable_library == null:
		return -1

	for i: int in range(story_data.variable_library.variable_list.size()):
		var v: StoryVariable = story_data.variable_library.variable_list[i]

		if v.name == variable.name:
			return i + 1

	return -1


func _refresh_variable_picker() -> void:
	variable_picker.clear()

	if story_data == null:
		return

	variable_picker.add_item('None')
	variable_picker.set_item_id(0, -1)
	variable_picker.select(0)

	if story_data.variable_library == null:
		return

	for variable: StoryVariable in story_data.variable_library.variable_list:
		var index: int = variable_picker.item_count
		variable_picker.add_item(String(variable.name))
		variable_picker.set_item_id(index, index - 1)

		if branch_node != null and branch_node.variable == variable:
			variable_picker.select(index)


func _refresh_condition_rows() -> void:
	for child: Control in get_children():
		if child is ConditionRow:
			child.free()

	if branch_node == null or branch_node.variable == null:
		return

	for condition: BranchCondition in branch_node.conditions:
		var condition_row: ConditionRow = CONDITION_ROW_SCENE.instantiate() as ConditionRow

		if condition_row == null:
			push_error('Failed to instantiate ConditionRow')
			continue

		var new_condition_index: int = get_children().find(new_condition_button)
		add_child(condition_row)
		move_child(condition_row, new_condition_index)
		condition_row.set_condition(condition)
		condition_row.set_variable(branch_node.variable)
		condition_row.delete_requested.connect(_on_condition_delete_requested)

		var condition_index: int = branch_node.conditions.find(condition)
		condition_row.set_meta('condition_index', condition_index)
		condition_row.drag_handle.drag_data = condition_index

		condition_row.drag_handle.set_drag_forwarding(
			Callable(),
			_can_drop_data,
			_drop_from.bind(condition_row),
		)

		if not condition.changed.is_connected(_on_condition_changed):
			condition.changed.connect(_on_condition_changed)

		var slot_index: int = get_children().find(condition_row)
		set_slot_enabled_right(slot_index, true)
		set_slot_type_right(slot_index, 0)

	var new_condition_index: int = get_children().find(new_condition_button)

	if new_condition_index >= 0:
		set_slot_enabled_right(new_condition_index, false)

	call_deferred('reset_size')


func _on_condition_changed() -> void:
	if story_data == null:
		return

	story_data.emit_changed()


func _on_condition_delete_requested(condition: BranchCondition) -> void:
	if story_data == null:
		return

	var condition_index: int = branch_node.conditions.find(condition)

	if condition_index < 0:
		return

	var undo_redo := story_data.undo_redo
	var links: Array[StoryLink] = story_data.get_links_from_port(
		branch_node.instance_id,
		condition_index,
	)

	undo_redo.create_action('Delete Condition')

	undo_redo.add_do_method(story_data.remove_links.bind(links))
	undo_redo.add_do_method(story_data.shift_link_ports.bind(
			branch_node.instance_id,
			condition_index,
		))
	undo_redo.add_do_method(_remove_condition.bind(condition, true))

	undo_redo.add_undo_method(_add_condition.bind(condition, true))
	undo_redo.add_undo_method(story_data.add_links.bind(links))
	undo_redo.add_undo_method(story_data.unshift_link_ports.bind(
			branch_node.instance_id,
			condition_index,
		))
	story_data.update_revision()

	undo_redo.commit_action()


func _drop_from(target_position: Vector2, data: Variant, source_control: Control) -> void:
	if not data is int:
		return

	if branch_node == null:
		return

	var source_index: int = data
	var target_index: int = source_control.get_meta('condition_index')

	if source_index == target_index:
		return

	if source_index < 0 or source_index >= branch_node.conditions.size():
		return

	if target_index < 0 or target_index >= branch_node.conditions.size():
		return

	var condition: BranchCondition = branch_node.conditions[source_index]
	branch_node.conditions.remove_at(source_index)
	branch_node.conditions.insert(target_index, condition)

	if story_data != null:
		story_data.move_link_port(branch_node.instance_id, source_index, target_index)

	_refresh_condition_rows()
	ports_changed.emit()


func _refresh_condition_rows_and_notify() -> void:
	_refresh_condition_rows()
	ports_changed.emit()
