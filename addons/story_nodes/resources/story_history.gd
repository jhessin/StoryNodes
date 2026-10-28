@tool
class_name StoryHistory
extends RefCounted
## Nesting-safe wrapper around UndoRedo. Only the outermost begin()/commit()
## pair opens and commits a real action, and the action opens lazily, so a
## transaction that records nothing leaves no empty entry in history.

var undo_redo: UndoRedo = UndoRedo.new()

var _depth: int = 0
var _open: bool = false
var _name: String = ''
var _merge: UndoRedo.MergeMode = UndoRedo.MERGE_DISABLE
var _replaying: int = 0


func is_replaying() -> bool:
	return _replaying > 0


func undo() -> bool:
	_replaying += 1
	var result: bool = undo_redo.undo()
	_replaying -= 1
	return result


func redo() -> bool:
	_replaying += 1
	var result: bool = undo_redo.redo()
	_replaying -= 1
	return result


func begin(action_name: String, merge: UndoRedo.MergeMode = UndoRedo.MERGE_DISABLE) -> void:
	if is_replaying():
		return
	if _depth == 0:
		_name = action_name
		_merge = merge
	_depth += 1


func commit() -> void:
	if is_replaying():
		return
	if _depth == 0:
		push_error('StoryHistory.commit() without begin().')
		return
	_depth -= 1
	if _depth == 0 and _open:
		_open = false
		_replaying += 1
		undo_redo.commit_action()
		_replaying -= 1


func transact(action_name: String, build: Callable) -> void:
	begin(action_name)
	build.call()
	commit()


func record(
	action_name: String,
	do_call: Callable,
	undo_call: Callable,
	notify: Callable = Callable(),
) -> void:
	if is_replaying():
		do_call.call()
		if notify.is_valid():
			notify.call()
		return

	begin(action_name)
	_ensure_open()
	undo_redo.add_do_method(do_call)
	undo_redo.add_undo_method(undo_call)
	if notify.is_valid():
		undo_redo.add_do_method(notify)
		undo_redo.add_undo_method(notify)
	commit()


func record_property(
	action_name: String,
	object: Object,
	property: StringName,
	new_value: Variant,
	old_value: Variant,
	notify: Callable = Callable(),
) -> void:
	if is_replaying():
		object.set(property, new_value)
		if notify.is_valid():
			notify.call()
		return

	begin(action_name)
	_ensure_open()
	undo_redo.add_do_property(object, property, new_value)
	undo_redo.add_undo_property(object, property, old_value)
	if notify.is_valid():
		undo_redo.add_do_method(notify)
		undo_redo.add_undo_method(notify)
	commit()


func _ensure_open() -> void:
	if _open:
		return
	undo_redo.create_action(_name, _merge)
	_open = true
