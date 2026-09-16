@tool
class_name StorySettings
extends RefCounted

const CHARACTER_LIBRARY_SETTING: String = 'story_nodes/character_library_path'
const DEFAULT_CHARACTER_LIBRARY_PATH: String = 'res://character_library.tres'


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


static func get_character_library_path() -> String:
	return ProjectSettings.get_setting(CHARACTER_LIBRARY_SETTING, DEFAULT_CHARACTER_LIBRARY_PATH)
