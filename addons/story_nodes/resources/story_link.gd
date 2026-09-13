class_name StoryLink
extends Resource

@export_storage
var from: StringName = &""
@export_storage
var to: StringName = &""


func _init(_from: StringName = &'', _to: StringName = &'') -> void:
	from = _from
	to = _to
