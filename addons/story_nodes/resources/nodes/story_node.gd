@tool
class_name StoryNode
extends Resource

@export var node_id: StringName = &'StoryNode'
@export var instance_id: StringName = &""

@export var graph_scene: PackedScene
@export var runtime_scene: PackedScene

@export var display_name: String = ""

@export_multiline var description: String = ""

@export_storage
var position: Vector2 = Vector2.ZERO

@export_storage
var size: Vector2 = Vector2.ZERO
