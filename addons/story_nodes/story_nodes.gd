@tool
extends EditorPlugin

var story_graph_editor: Control


func _enter_tree() -> void:
	story_graph_editor = preload('res://addons/story_nodes/editor/story_graph_editor.tscn').instantiate()

	EditorInterface.get_editor_main_screen().add_child(story_graph_editor)


func _exit_tree() -> void:
	if story_graph_editor != null:
		story_graph_editor.queue_free()


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return 'Story'


func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon('Node', 'EditorIcons')


func _make_visible(visible: bool) -> void:
	if story_graph_editor != null:
		story_graph_editor.visible = visible
