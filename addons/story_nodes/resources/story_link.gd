@tool
class_name StoryLink
extends Resource

@export_storage
var from: StringName = &""

@export_storage
var to: StringName = &""

@export_storage
var from_port: int = 0

@export_storage
var to_port: int = 0


func _init(_from: StringName = &'', _to: StringName = &'', _from_port: int = 0, _to_port: int = 0) -> void:
	from = _from
	to = _to
	from_port = _from_port
	to_port = _to_port
