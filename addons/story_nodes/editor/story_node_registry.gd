@tool
class_name StoryNodeRegistry
extends RefCounted

static var _instance: StoryNodeRegistry

var classes: Array[StringName]:
	get:
		return _scripts.keys()
var paths: Dictionary[StringName, String]:
	get:
		var result: Dictionary[StringName, String] = { }
		for id: StringName in _scripts:
			result[id] = _scripts[id].resource_path
		return result
var _scripts: Dictionary[StringName, Script] = { }


static func get_instance() -> StoryNodeRegistry:
	if _instance == null:
		_instance = StoryNodeRegistry.new()

	return _instance


# static func is_initialized() -> bool:
# 	return _instance != null
func rebuild() -> void:
	_scripts.clear()

	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
	var root: EditorFileSystemDirectory = filesystem.get_filesystem()

	_scan_directory(root)


func get_node_script(cls: StringName) -> Script:
	if not _scripts.has(cls):
		push_error("StoryNodeRegistry: Unknown StoryNode class '%s'." % cls)
		return null

	return _scripts[cls]


func get_script_path(cls: StringName) -> String:
	if not _scripts.has(cls):
		push_error('StoryNodeRegistry: Unknown StoryNode class "%s".' % cls)
		return ''
	return _scripts[cls].resource_path


func has_class(cls: StringName) -> bool:
	return _scripts.has(cls)


func create_node(node_class_name: StringName) -> StoryNode:
	var script: Script = get_node_script(node_class_name)

	if script == null:
		return null

	var node: StoryNode = script.new() as StoryNode

	if node == null:
		push_error(
			"StoryNodeRegistry: Script for '%s' did not create a StoryNode." % node_class_name
		)
		return null

	return node


func _scan_directory(directory: EditorFileSystemDirectory) -> void:
	for index: int in range(directory.get_file_count()):
		var file_name: String = directory.get_file(index)

		if not file_name.ends_with(".gd"):
			continue

		var script: Script = load(directory.get_file_path(index)) as Script

		if script == null:
			push_error(
				"StoryNodeRegistry: Failed to load script '%s'." % directory.get_file_path(index)
			)
			continue

		_register_if_story_node(script)

	for index: int in directory.get_subdir_count():
		var subdirectory: EditorFileSystemDirectory = directory.get_subdir(index)
		_scan_directory(subdirectory)


func _register_if_story_node(script: Script) -> void:
	var cls: StringName = script.get_global_name()

	if cls == &"":
		return

	if cls == &'StoryNode':
		return

	var base_script: Script = script.get_base_script()

	while base_script != null:
		if base_script.get_global_name() == &'StoryNode':
			if _scripts.has(cls):
				push_error("StoryNodeRegistry: Duplicate StoryNode class name '%s'." % cls)
				return

			_scripts[cls] = script
			return

		base_script = base_script.get_base_script()
