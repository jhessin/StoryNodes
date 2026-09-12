class_name StoryLink
extends RefCounted

var from: StringName = &""
var to: StringName = &""


func _init(_from: StringName = &'', _to: StringName = &'') -> void:
	from = _from
	to = _to
