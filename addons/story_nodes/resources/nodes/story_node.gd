@tool
class_name StoryNode
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""

@export_multiline var description: String = ""

@export_storage
var position: Vector2 = Vector2.ZERO


func _init(_id: StringName = &'', name: String = '', _description: String = '') -> void:
	id = _id
	display_name = name
	description = _description


func execute(_execution: StoryExecution) -> void:
	pass
