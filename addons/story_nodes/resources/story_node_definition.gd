@tool
class_name StoryNodeDefinition
extends Resource

@export var id: StringName = &''
@export var display_name: String = ''

@export var graph_scene: PackedScene
@export var story_node_script: Script

@export var category: String = ''

@export var instantiable: bool = true

@export_multiline var description: String = ''
