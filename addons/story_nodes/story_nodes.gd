@tool
extends EditorPlugin

var story_editor: StoryEditor
var story_node_registry: StoryNodeRegistry


func _enter_tree() -> void:
	StorySettings.register_project_settings()

	story_editor = preload('res://addons/story_nodes/editor/story_editor.tscn').instantiate()
	story_node_registry = StoryNodeRegistry.get_instance()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)

	EditorInterface.get_editor_main_screen().add_child(story_editor)

	_make_visible(false)


func _exit_tree() -> void:
	if story_editor != null:
		story_editor.queue_free()


func _on_filesystem_changed() -> void:
	story_node_registry.rebuild()

	for node_class_name: StringName in story_node_registry.classes:
		print("StoryNodes: Found '%s'." % node_class_name)

	var test_script: Script = story_node_registry.get_node_script(&"DialogueNode")

	if test_script == null:
		push_error("StoryNodes: Failed to resolve DialogueNode.")
	else:
		print("StoryNodes: DialogueNode script = ", test_script.resource_path)

	var test_node: StoryNode = story_node_registry.create_node(&"DialogueNode")

	if test_node == null:
		push_error("StoryNodes: Failed to create DialogueNode.")
	else:
		print("StoryNodes: Created ", test_node.get_script().get_global_name())


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return 'Story'


func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon('Node', 'EditorIcons')


func _make_visible(visible: bool) -> void:
	if story_editor != null:
		story_editor.visible = visible
