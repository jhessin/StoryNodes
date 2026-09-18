@tool
class_name StoryLink
extends Resource

var id: StringName:
	get:
		return "%s_%s_%s_%s" % [from, from_port, to, to_port] as StringName

@export_storage
var from: StringName = &""

@export_storage
var to: StringName = &""

@export_storage
var from_port: int = 0

@export_storage
var to_port: int = 0
