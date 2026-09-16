@tool
class_name StoryVariable
extends Resource

enum Type {
	BOOL,
	INT,
	FLOAT,
	STRING,
}

@export var name: StringName = &''
@export var type: Type = Type.STRING
@export var default_value: Variant = ''


func _init(
	variable_name: StringName = &'',
	variable_type: Type = Type.STRING,
	variable_default_value: Variant = '',
) -> void:
	name = variable_name
	type = variable_type
	default_value = variable_default_value
