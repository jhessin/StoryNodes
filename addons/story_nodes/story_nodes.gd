@tool
extends EditorPlugin

var story_editor: StoryEditor


func _enter_tree() -> void:
	story_editor = preload('res://addons/story_nodes/editor/story_editor.tscn').instantiate()

	EditorInterface.get_editor_main_screen().add_child(story_editor)

	_make_visible(false)


func _exit_tree() -> void:
	if story_editor != null:
		story_editor.queue_free()


func _handles(object: Object) -> bool:
	return object is StoryData


func _edit(object: Object) -> void:
	if object is StoryData:
		story_editor.set_story_data(object as StoryData)


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return 'Story'


func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon('Node', 'EditorIcons')


func _make_visible(visible: bool) -> void:
	if story_editor != null:
		story_editor.visible = visible
