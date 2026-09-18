@tool
class_name StorySettings
extends RefCounted

const CHARACTER_LIBRARY_SETTING: String = 'story_nodes/character_library_path'
const DEFAULT_CHARACTER_LIBRARY_PATH: String = 'res://character_library.tres'
const VARIABLE_LIBRARY_SETTING: String = 'story_nodes/variable_library_path'
const DEFAULT_VARIABLE_LIBRARY_PATH: String = 'res://variable_library.tres'


static func register_project_settings() -> void:
	if not ProjectSettings.has_setting(CHARACTER_LIBRARY_SETTING):
		ProjectSettings.set_setting(CHARACTER_LIBRARY_SETTING, DEFAULT_CHARACTER_LIBRARY_PATH)

	ProjectSettings.add_property_info(
		{
			'name': CHARACTER_LIBRARY_SETTING,
			'type': TYPE_STRING,
			'hint': PROPERTY_HINT_FILE,
			'hint_string': '*.tres',
		}
	)

	if not ProjectSettings.has_setting(VARIABLE_LIBRARY_SETTING):
		ProjectSettings.set_setting(VARIABLE_LIBRARY_SETTING, DEFAULT_VARIABLE_LIBRARY_PATH)

	ProjectSettings.add_property_info(
		{
			'name': VARIABLE_LIBRARY_SETTING,
			'type': TYPE_STRING,
			'hint': PROPERTY_HINT_FILE,
			'hint_string': '*.tres',
		}
	)


static func get_character_library_path() -> String:
	return ProjectSettings.get_setting(CHARACTER_LIBRARY_SETTING, DEFAULT_CHARACTER_LIBRARY_PATH)


static func get_variable_library_path() -> String:
	return ProjectSettings.get_setting(VARIABLE_LIBRARY_SETTING, DEFAULT_VARIABLE_LIBRARY_PATH)


static func get_standard_library() -> StoryNodeLibrary:
	return preload('res://addons/story_nodes/resources/libraries/standard_node_library.tres')
